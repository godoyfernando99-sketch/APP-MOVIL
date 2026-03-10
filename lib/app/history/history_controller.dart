import 'package:flutter/material.dart';
import 'scan_models.dart';
import '../storage/local_db.dart';

class HistoryController extends ChangeNotifier {
  final LocalDb _localDb = LocalDb();
  List<ScanResult> _history = [];

  List<ScanResult> get history => _history;

  // Corregido: Agregado el método init()
  Future<void> init() async {
    await loadHistory();
  }

  // Corregido: Agregado el método refresh()
  Future<void> refresh() async {
    await loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await _localDb.getHistory();
    _history = data.map((e) => ScanResult.fromMap(e)).toList();
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> addScan(ScanResult result) async {
    _history.insert(0, result);
    await _localDb.setHistory(_history.map((e) => e.toMap()).toList());
    notifyListeners();
  }
}