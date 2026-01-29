import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local key/value storage.
///
/// This is a placeholder until you connect Firebase/Supabase in Dreamflow.
class LocalDb {
  static const String _usersKey = 'users_v1';
  static const String _currentUserKey = 'current_user_v1';
  static const String _historyKey = 'scan_history_v1';
  static const String _localeKey = 'locale_v1';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<String?> getLocaleCode() async {
    try {
      return (await _prefs()).getString(_localeKey);
    } catch (e) {
      debugPrint('LocalDb.getLocaleCode failed: $e');
      return null;
    }
  }

  Future<void> setLocaleCode(String code) async {
    try {
      await (await _prefs()).setString(_localeKey, code);
    } catch (e) {
      debugPrint('LocalDb.setLocaleCode failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final raw = (await _prefs()).getString(_usersKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      debugPrint('LocalDb.getUsers failed: $e');
      return [];
    }
  }

  Future<void> setUsers(List<Map<String, dynamic>> users) async {
    try {
      await (await _prefs()).setString(_usersKey, jsonEncode(users));
    } catch (e) {
      debugPrint('LocalDb.setUsers failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final raw = (await _prefs()).getString(_currentUserKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return null;
    } catch (e) {
      debugPrint('LocalDb.getCurrentUser failed: $e');
      return null;
    }
  }

  Future<void> setCurrentUser(Map<String, dynamic>? user) async {
    try {
      final prefs = await _prefs();
      if (user == null) {
        await prefs.remove(_currentUserKey);
      } else {
        await prefs.setString(_currentUserKey, jsonEncode(user));
      }
    } catch (e) {
      debugPrint('LocalDb.setCurrentUser failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];
      
      // Validar que el JSON no esté corrupto antes de decodificar
      if (raw.length > 10000000) {
        debugPrint('History data too large (${raw.length} chars), clearing...');
        await prefs.remove(_historyKey);
        return [];
      }
      
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        debugPrint('History data is not a list, clearing...');
        await prefs.remove(_historyKey);
        return [];
      }
      
      return decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      debugPrint('LocalDb.getHistory failed: $e');
      // Si hay error al decodificar, limpiar el historial corrupto
      try {
        final prefs = await _prefs();
        await prefs.remove(_historyKey);
        debugPrint('Corrupted history cleared');
      } catch (e2) {
        debugPrint('Failed to clear corrupted history: $e2');
      }
      return [];
    }
  }

  Future<void> setHistory(List<Map<String, dynamic>> history) async {
    try {
      final prefs = await _prefs();
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      debugPrint('LocalDb.setHistory failed: $e');
      // Si falla por cuota excedida, intentar limpiar historial antiguo
      if (e.toString().contains('QuotaExceededError')) {
        debugPrint('Storage quota exceeded. Clearing old history...');
        try {
          final prefs = await _prefs();
          // Mantener solo los últimos 5 registros
          final reducedHistory = history.length > 5 ? history.sublist(history.length - 5) : history;
          await prefs.setString(_historyKey, jsonEncode(reducedHistory));
          debugPrint('History reduced to ${reducedHistory.length} items');
        } catch (e2) {
          debugPrint('Failed to reduce history: $e2');
          // Si aún falla, limpiar todo el historial
          try {
            final prefs = await _prefs();
            await prefs.remove(_historyKey);
          } catch (e3) {
            debugPrint('Failed to clear history: $e3');
          }
        }
      }
    }
  }
}
