import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import '../storage/local_db.dart'; 

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
          _clearLocalOnLogout();
        } else if (_currentUserId != user.uid) {
          _currentUserId = user.uid;
          refresh();
        }
      });
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
    if (_isLoading) return; 
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

      final query = await _firestore
          .collection('scanResults')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache)); 

      final localHistory = await _localDb.getHistory();
      final localMap = <String, Map<String, dynamic>>{};
      
      for (final json in localHistory) {
        final id = json['id']?.toString();
        if (id != null) {
          localMap[id] = json;
        }
      }

      final firebaseItems = <ScanResult>[];
      for (final doc in query.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;

          // RECOMBINACIÓN MEJORADA: 
          // Si tenemos el registro en local, recuperamos las fotos Y 
          // cualquier campo que Firebase pudiera no tener.
          if (localMap.containsKey(doc.id)) {
            data['photosBase64'] = localMap[doc.id]?['photosBase64'];
            // Aseguramos que si en local ya teníamos raza/alimento, se mantengan
            data['animalType'] ??= localMap[doc.id]?['animalType'];
            data['detectedBreed'] ??= localMap[doc.id]?['detectedBreed'];
            data['foodRecommendation'] ??= localMap[doc.id]?['foodRecommendation'];
          }

          firebaseItems.add(ScanResult.fromMap(data));
        } catch (e) {
          debugPrint('Error parseando escaneo de Firebase: $e');
        }
      }

      _items = firebaseItems;
      notifyListeners();

      // Guardamos la lista completa actualizada en local
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

      final itemWithOwner = item.copyWith(
        ownerId: user?.uid ?? 'local',
      );

      // 1. Actualizar UI inmediatamente
      _items = [itemWithOwner, ..._items];
      notifyListeners();

      // 2. Guardar en local (incluye fotos y campos nuevos)
      final currentHistoryMap = _items.map((e) => e.toMap()).toList();
      await _localDb.setHistory(currentHistoryMap);

      // 3. Sincronizar con Firebase (sin fotos para ahorrar espacio)
      if (user != null) {
        _saveToFirebase(itemWithOwner).catchError((e) {
          debugPrint('Firebase save failed: $e');
        });
      }
    } catch (e) {
      debugPrint('[HistoryController] add() failed: $e');
      rethrow;
    }
  }

  Future<void> _saveToFirebase(ScanResult item) async {
    try {
      final mapData = item.toMap();
      
      // Eliminamos fotos antes de subir a Firestore por límite de 1MB por doc
      mapData.remove('photosBase64'); 

      // IMPORTANTE: Asegúrate de que tu modelo ScanResult incluya 
      // animalType, detectedBreed y foodRecommendation en su toMap()
      await _firestore
          .collection('scanResults')
          .doc(item.id)
          .set(mapData, SetOptions(merge: true));

      debugPrint('[HistoryController] ✓ Sincronizado en la nube');
    } catch (e) {
      debugPrint('[HistoryController] Error en sincronización: $e');
      rethrow;
    }
  }
}