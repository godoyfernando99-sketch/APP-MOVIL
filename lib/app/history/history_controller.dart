import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/local_db.dart'; // Verifica que la ruta sea correcta

class HistoryController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDb _localDb = LocalDb();

  List<ScanResult> _items = [];
  List<ScanResult> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _currentUserId;

  Future<void> init() async {
    try {
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          debugPrint('[HistoryController] Usuario cerró sesión, limpiando historial local...');
          _clearLocalOnLogout();
        } else if (_currentUserId != user.uid) {
          debugPrint('[HistoryController] Nuevo usuario detectado: ${user.uid}');
          _currentUserId = user.uid;
          refresh();
        }
      });
      // Carga inicial rápida desde local antes de ir a red
      await _loadFromLocalStorage();
      await refresh();
    } catch (e) {
      debugPrint('[HistoryController] init() failed: $e');
    }
  }
  
  Future<void> _clearLocalOnLogout() async {
    try {
      await _localDb.setHistory([]);
      _items = [];
      _currentUserId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[HistoryController] Error limpiando historial: $e');
    }
  }

  Future<void> refresh() async {
    if (_isLoading) return; // Evitar múltiples refrescos simultáneos
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        await _loadFromFirebase();
      } else {
        await _loadFromLocalStorage();
      }
    } catch (e) {
      debugPrint('HistoryController.refresh failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Consultar Firebase con un try-catch específico por si no hay conexión
      final query = await _firestore
          .collection('scanResults')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache)); // Prioriza servidor pero usa cache si falla

      // Mapear imágenes locales para recombinarlas
      final localHistory = await _localDb.getHistory();
      final localMap = <String, List<String>>{};
      for (final json in localHistory) {
        final id = json['id']?.toString();
        if (id != null && json['photosBase64'] != null) {
          localMap[id] = List<String>.from(json['photosBase64']);
        }
      }
      
      final firebaseItems = <ScanResult>[];
      for (final doc in query.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // RECOMBINACIÓN: Si en local tengo las fotos de este ID de Firebase, las pongo
          if (localMap.containsKey(doc.id)) {
            data['photosBase64'] = localMap[doc.id];
          }
          
          firebaseItems.add(ScanResult.fromMap(data));
        } catch (e) {
          debugPrint('Error parseando escaneo de Firebase: $e');
        }
      }

      _items = firebaseItems;
      notifyListeners();

      // Sincronizar localmente (importante para mantener las fotos que ya existían)
      await _localDb.setHistory(_items.map((e) => e.toMap()).toList());
    } catch (e) {
      debugPrint('[HistoryController] Error Firebase (cargando local...): $e');
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final localHistory = await _localDb.getHistory();
      final parsed = <ScanResult>[];
      for (final json in localHistory) {
        try {
          parsed.add(ScanResult.fromMap(json));
        } catch (e) {
          debugPrint('Error parseando local: $e');
        }
      }

      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _items = parsed;
      notifyListeners();
    } catch (e) {
      debugPrint('[HistoryController] Error local storage: $e');
    }
  }

  Future<void> add(ScanResult item) async {
    try {
      final user = _auth.currentUser;
      
      final itemWithOwner = item.copyWith(
        ownerId: user?.uid ?? 'local',
      );

      // 1. Guardar en local storage INMEDIATAMENTE para respuesta instantánea
      _items = [itemWithOwner, ..._items];
      notifyListeners();
      
      final currentHistoryMap = _items.map((e) => e.toMap()).toList();
      await _localDb.setHistory(currentHistoryMap);
      
      // 2. Intentar guardar en Firebase en segundo plano
      if (user != null) {
        // Ignoramos el await para que la UI no espere a la red
        _saveToFirebase(itemWithOwner).catchError((e) {
          debugPrint('Firebase save failed (non-critical): $e');
        });
      }
      
    } catch (e) {
      debugPrint('[HistoryController] add() failed: $e');
      rethrow;
    }
  }

  Future<void> _saveToFirebase(ScanResult item) async {
    try {
      // Preparamos los datos quitando las fotos pesadas
      final mapData = item.toMap();
      mapData.remove('photosBase64'); 
      
      // Usamos set con merge por si el documento ya existía parcialmente
      await _firestore
          .collection('scanResults')
          .doc(item.id)
          .set(mapData, SetOptions(merge: true));
          
      debugPrint('[HistoryController] ✓ Sincronizado con la nube');
    } catch (e) {
      debugPrint('[HistoryController] Error en sincronización Cloud: $e');
      rethrow;
    }
  }
}
