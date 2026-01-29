import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/app/storage/local_db.dart';

class HistoryController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDb _localDb = LocalDb();

  List<ScanResult> _items = const [];
  List<ScanResult> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _currentUserId;

  Future<void> init() async {
    try {
      // Escuchar cambios de autenticación
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          // Usuario cerró sesión - limpiar historial local
          debugPrint('[HistoryController] Usuario cerró sesión, limpiando historial local...');
          _clearLocalOnLogout();
        } else if (_currentUserId != user.uid) {
          // Usuario cambió o inició sesión - recargar historial
          debugPrint('[HistoryController] Nuevo usuario detectado: ${user.uid}');
          _currentUserId = user.uid;
          refresh();
        }
      });
      
      await refresh();
    } catch (e) {
      debugPrint('[HistoryController] init() failed: $e');
      // No bloquear la app si falla la inicialización del historial
    }
  }
  
  Future<void> _clearLocalOnLogout() async {
    try {
      await _localDb.setHistory([]);
      _items = [];
      _currentUserId = null;
      notifyListeners();
      debugPrint('[HistoryController] ✓ Historial limpiado tras cerrar sesión');
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
        // Si hay usuario autenticado, cargar SIEMPRE desde Firebase primero
        debugPrint('[HistoryController] Usuario autenticado: ${user.uid}');
        debugPrint('[HistoryController] Cargando historial desde Firebase...');
        await _loadFromFirebase();
      } else {
        // Si no hay usuario, cargar desde almacenamiento local
        debugPrint('[HistoryController] Sin usuario autenticado, cargando desde local storage...');
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
      if (user == null) {
        debugPrint('[HistoryController] No hay usuario autenticado');
        return;
      }

      debugPrint('[HistoryController] Consultando Firebase para usuario: ${user.uid}');
      final query = await _firestore
          .collection('scanResults')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      debugPrint('[HistoryController] Firebase retornó ${query.docs.length} documentos');
      
      // Cargar local storage para obtener las imágenes
      final localHistory = await _localDb.getHistory();
      final localMap = <String, Map<String, dynamic>>{};
      for (final json in localHistory) {
        final id = json['id']?.toString();
        if (id != null) localMap[id] = json;
      }
      debugPrint('[HistoryController] Local storage tiene ${localMap.length} items con imágenes');
      
      final firebaseItems = <ScanResult>[];
      for (final doc in query.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Combinar metadatos de Firebase con imágenes de local storage
          final localData = localMap[doc.id];
          if (localData != null && localData['photosBase64'] is List) {
            data['photosBase64'] = localData['photosBase64'];
          }
          
          firebaseItems.add(ScanResult.fromJson(data));
        } catch (e) {
          debugPrint('Failed to parse Firebase scan result: $e');
        }
      }

      debugPrint('[HistoryController] Parseados exitosamente ${firebaseItems.length} escaneos desde Firebase');
      _items = firebaseItems;
      notifyListeners();

      // Guardar combinación en local storage (metadatos + imágenes)
      await _localDb.setHistory(_items.map((e) => e.toJson()).toList());
      debugPrint('[HistoryController] ✓ Historial sincronizado con local storage');
    } catch (e) {
      debugPrint('[HistoryController] Error cargando desde Firebase: $e');
      // Si falla Firebase, intentar cargar desde local storage como respaldo
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final localHistory = await _localDb.getHistory();
      debugPrint('[HistoryController] Found ${localHistory.length} items in local storage');
      
      final parsed = <ScanResult>[];
      for (final json in localHistory) {
        try {
          parsed.add(ScanResult.fromJson(json));
        } catch (e) {
          debugPrint('Failed to parse local scan result: $e');
        }
      }

      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _items = parsed;
      notifyListeners();
      debugPrint('[HistoryController] Successfully loaded ${parsed.length} scan results from local');
    } catch (e) {
      debugPrint('[HistoryController] Error loading from local storage: $e');
      _items = [];
      notifyListeners();
    }
  }

  Future<void> add(ScanResult item) async {
    try {
      final user = _auth.currentUser;
      final now = DateTime.now();
      
      debugPrint('[HistoryController] Adding new scan result to history...');
      
      final itemWithOwner = item.copyWith(
        ownerId: user?.uid ?? 'local',
        createdAt: now,
        updatedAt: now,
      );

      // Guardar en almacenamiento local SIEMPRE
      final currentHistory = await _localDb.getHistory();
      debugPrint('[HistoryController] Current history has ${currentHistory.length} items');
      
      final updatedHistory = [itemWithOwner.toJson(), ...currentHistory];
      await _localDb.setHistory(updatedHistory);
      
      debugPrint('[HistoryController] ✓ Scan result saved to local storage (total: ${updatedHistory.length})');

      // Intentar guardar en Firebase (sin bloquear si falla)
      if (user != null) {
        _saveToFirebase(itemWithOwner).catchError((e) {
          debugPrint('Firebase save failed (non-critical): $e');
        });
      }

      // Actualizar UI inmediatamente con datos locales
      debugPrint('[HistoryController] Refreshing UI with updated history...');
      await refresh();
    } catch (e) {
      debugPrint('[HistoryController] add() failed: $e');
      rethrow;
    }
  }

  Future<void> _saveToFirebase(ScanResult item) async {
    try {
      // Guardar SIN imágenes en Firebase (solo metadatos) para evitar límite de 1MB
      // Las imágenes se mantienen en local storage
      final itemWithoutPhotos = item.copyWith(photosBase64: []);
      await _firestore.collection('scanResults').doc(item.id).set(itemWithoutPhotos.toFirestoreJson());
      debugPrint('[HistoryController] ✓ Escaneo guardado en Firebase con ID: ${item.id} (sin imágenes)');
    } catch (e) {
      debugPrint('[HistoryController] Error guardando en Firebase: $e');
      rethrow;
    }
  }

  /// Limpiar historial local (útil al cerrar sesión)
  Future<void> clearLocalHistory() async {
    try {
      await _localDb.setHistory([]);
      _items = [];
      notifyListeners();
      debugPrint('[HistoryController] ✓ Historial local limpiado');
    } catch (e) {
      debugPrint('[HistoryController] Error limpiando historial local: $e');
    }
  }
}
