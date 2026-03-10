import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDb {
  static const String _usersKey = 'users_v1';
  static const String _currentUserKey = 'current_user_v1';
  static const String _historyKey = 'scan_history_v1';
  static const String _localeKey = 'locale_v1';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // --- LOCALE ---
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

  // --- USUARIOS ---
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

  // --- HISTORIAL (CON PROTECCIÓN DE MEMORIA PARA FOTOS) ---
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];

      // Límite de seguridad: 15MB (SharedPreferences suele aguantar hasta 20-30MB en Android moderno)
      if (raw.length > 15000000) { 
        debugPrint('⚠️ Historial muy pesado (${raw.length} caracteres), reduciendo...');
        // No borramos todo, solo avisamos para que el setHistory limpie en la siguiente vuelta
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await prefs.remove(_historyKey);
        return [];
      }

      return decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (e) {
      debugPrint('LocalDb.getHistory failed: $e');
      return [];
    }
  }

  Future<void> setHistory(List<Map<String, dynamic>> history) async {
    try {
      final prefs = await _prefs();
      
      // OPTIMIZACIÓN: Si el historial tiene más de 20 elementos, mantenemos solo los 20 más recientes
      // Esto evita que las fotos acumuladas rompan la app.
      List<Map<String, dynamic>> optimizedHistory = history;
      if (history.length > 20) {
        optimizedHistory = history.sublist(0, 20);
      }

      final String encoded = jsonEncode(optimizedHistory);
      
      // Verificación de tamaño antes de intentar guardar
      if (encoded.length > 18000000) { // ~18MB
        debugPrint('⚠️ Alerta de espacio: El historial es demasiado grande. Guardando solo los últimos 10.');
        final reduced = optimizedHistory.take(10).toList();
        await prefs.setString(_historyKey, jsonEncode(reduced));
      } else {
        await prefs.setString(_historyKey, encoded);
      }
      
    } catch (e) {
      debugPrint('LocalDb.setHistory failed: $e');
      // Manejo de emergencia para QuotaExceededError
      if (e.toString().contains('QuotaExceeded') || e.toString().contains('limit')) {
        final prefs = await _prefs();
        // Plan de rescate: Guardar solo los últimos 3 escaneos (lo más importante)
        final emergencyHistory = history.take(3).toList();
        await prefs.setString(_historyKey, jsonEncode(emergencyHistory));
        debugPrint('🚨 Cuota excedida. Se guardaron solo los 3 registros más recientes.');
      }
    }
  }
}