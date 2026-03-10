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
  String? _currentUserId;

  // ALIAS PARA COMPATIBILIDAD CON LA UI
  Future<void> saveScan(ScanResult item) async {
    await add(item);
  }

  Future<void> add(ScanResult item) async {
    try {
      final user = _auth.currentUser;
      final itemWithData = item.copyWith(ownerId: user?.uid ?? 'local');

      // 1. Actualizar memoria
      _items = [itemWithData, ..._items];
      notifyListeners();

      // 2. Guardar Local (con fotos y notas)
      await _localDb.setHistory(_items.map((e) => e.toMap()).toList());

      // 3. Sincronizar Firebase (sin fotos por peso, pero con notas)
      if (user != null) {
        final mapData = itemWithData.toMap();
        mapData.remove('photosBase64'); 
        await _firestore.collection('scanResults').doc(itemWithData.id).set(mapData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[HistoryController] Error al guardar: $e');
      rethrow;
    }
  }
  
  // ... (puedes mantener el resto de tus funciones init, refresh, etc. igual)
}