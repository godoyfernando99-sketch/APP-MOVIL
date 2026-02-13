import 'dart:convert';
import 'dart:typed_material'; // Asegúrate de tener esta importación o solo dart:typed_data
import 'package:flutter/foundation.dart';

class OpenAiConfig {
  // Tu llave de Google Gemini (Confirmada como Google por el prefijo AIza)
  static const String apiKey = 'AIzaSyConmf0PN79jBFkNkHZRKMym2KcTNPI4gI';

  // Verifica que la llave esté puesta y tenga el formato correcto de Google
  static bool get isConfigured => apiKey.isNotEmpty && apiKey.startsWith('AIza');

  // Modo Real activo
  static const bool useMock = false;

  // --- ACTUALIZACIÓN: Endpoint estable v1 ---
  // Cambiamos a v1 para coincidir con la corrección en AiDiagnosisService
  static const String endpoint = 'https://generativelanguage.googleapis.com/v1';
  
  static Uri get uri => Uri.parse(endpoint);

  // Funciones de utilidad para compatibilidad
  static Map<String, String> headers() => {
    'Content-Type': 'application/json',
  };
  
  static String dataUrlFromBytes(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Método de respaldo para evitar errores de compilación en otras partes del código
  static Future<Map<String, dynamic>> postJson(Map<String, dynamic> body) async {
    // El análisis real lo realiza AiDiagnosisService.dart
    debugPrint("Advertencia: postJson en OpenAiConfig llamado, pero la lógica está en AiDiagnosisService.");
    return {};
  }
}
