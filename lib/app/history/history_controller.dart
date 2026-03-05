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
        } catch