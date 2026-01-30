import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAiConfig {
  // Tu llave de Google Gemini
  static const String apiKey = 'AIzaSyConmf0PN79jBFkNkHZRKMym2KcTNPI4gI';

  // Verifica que la llave esté puesta y sea de Google
  static bool get isConfigured => apiKey.isNotEmpty && apiKey.startsWith('AIza');

  // Modo Real activo
  static const bool useMock = false;

  // Endpoint de Gemini (No se usa directamente aquí, pero evita errores de compilación)
  static const String endpoint = 'https://generativelanguage.googleapis.com';
  static Uri get uri => Uri.parse(endpoint);

  // Funciones de utilidad para compatibilidad
  static Map<String, String> headers() => {
    'content-type': 'application/json; charset=utf-8',
  };
  
  static String dataUrlFromBytes(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Mantenemos este método para que la app no explote si otros archivos lo llaman
  static Future<Map<String, dynamic>> postJson(Map<String, dynamic> body) async {
    // Nota: El análisis real ahora lo hace el AiDiagnosisService
    // Este método queda aquí solo por seguridad estructural
    return {};
  }
}
