import 'package:flutter/material.dart';
import 'scan_models.dart';
import '../storage/local_db.dart';

class HistoryController extends ChangeNotifier {
  final LocalDb _localDb = LocalDb();
  List<ScanResult> _history = [];
  bool _isLoading = false;

  List<ScanResult> get history => _history;
  bool get isLoading => _isLoading;

  // CORREGIDO: Método init() solicitado por main.dart
  Future<void> init() async {
    await loadHistory();
  }

  // CORREGIDO: Método refresh() solicitado por HistoryPage
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await loadHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    try {
      final data = await _localDb.getHistory();
      _history = data.map((e) => ScanResult.fromMap(e)).toList();
      // Ordenar por fecha: los más nuevos primero
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar historial: $e');
    }
  }

  // SOLUCIÓN AL ERROR: Se añade saveScan para que scan_result_page.dart pueda compilar
  Future<void> saveScan(ScanResult result) async {
    _history.insert(0, result);
    await _localDb.setHistory(_history.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  Future<void> addScan(ScanResult result) async {
    _history.insert(0, result);
    await _localDb.setHistory(_history.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  Future<void> deleteScan(String id) async {
    _history.removeWhere((item) => item.id == id);
    await _localDb.setHistory(_history.map((e) => e.toMap()).toList());
    notifyListeners();
  }
}