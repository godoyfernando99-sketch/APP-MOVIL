import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/app/storage/local_db.dart';

class HistoryController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDb _localDb = LocalDb();

  List<ScanResult> _items = []; // Eliminado 'const' para permitir actualizaciones
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

      // Consultar Firebase
      final query = await _firestore
          .collection('scanResults')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Mapear imágenes locales para recombinarlas
      final localHistory = await _localDb.getHistory();
      final localMap = <String, Map<String, dynamic>>{};
      for (final json in localHistory) {
        final id = json['id']?.toString();
        if (id != null) localMap[id] = json;
      }
      
      final firebaseItems = <ScanResult>[];
      for (final doc in query.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Recombinar con imágenes locales si existen
          final localData = localMap[doc.id];
          if (localData != null && localData['photosBase64'] != null) {
            data['photosBase64'] = localData['photosBase64'];
          }
          
          firebaseItems.add(ScanResult.fromMap(data)); // Usamos fromMap
        } catch (e) {
          debugPrint('Error parseando escaneo de Firebase: $e');
        }
      }

      _items = firebaseItems;
      notifyListeners();

      // Sincronizar localmente
      await _localDb.setHistory(_items.map((e) => e.toMap()).toList());
    } catch (e) {
      debugPrint('[HistoryController] Error Firebase: $e');
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
      final now = DateTime.now();
      
      final itemWithOwner = item.copyWith(
        ownerId: user?.uid ?? 'local',
        createdAt: item.createdAt, // Mantener la fecha original si ya existe
      );

      // 1. Guardar en local storage (CON imágenes)
      final currentHistory = await _localDb.getHistory();
      final updatedHistory = [itemWithOwner.toMap(), ...currentHistory];
      await _localDb.setHistory(updatedHistory);
      
      // 2. Intentar guardar en Firebase (SIN imágenes para ahorrar espacio)
      if (user != null) {
        _saveToFirebase(itemWithOwner).catchError((e) {
          debugPrint('Firebase save failed (non-critical): $e');
        });
      }

      // 3. Actualizar lista en memoria y notificar UI
      _items = [itemWithOwner, ..._items];
      notifyListeners();
      
    } catch (e) {
      debugPrint('[HistoryController] add() failed: $e');
      rethrow;
    }
  }

  Future<void> _saveToFirebase(ScanResult item) async {
    try {
      // Usamos el método toMap() que ya configuramos en scan_models.dart
      // Eliminamos las fotos para no exceder el límite de documento de Firestore (1MB)
      final mapData = item.toMap();
      mapData.remove('photosBase64'); 
      
      await _firestore.collection('scanResults').doc(item.id).set(mapData);
      debugPrint('[HistoryController] ✓ Guardado en Firebase exitoso');
    } catch (e) {
      debugPrint('[HistoryController] Error guardando en Firebase: $e');
      rethrow;
    }
  }
}
