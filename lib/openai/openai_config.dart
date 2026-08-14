import 'dart:convert';
import 'dart:typed_data'; // CORREGIDO: ahora es typed_data
import 'package:flutter/foundation.dart';

class OpenAiConfig {
  // Tu llave de Google Gemini
  static const String apiKey = 'AIzaSyDTO3kzm9u7bOMHvuDEhujs9fVDZFc9xvs';

  // Verifica que la llave esté puesta y tenga el formato correcto de Google
  static bool get isConfigured => apiKey.isNotEmpty && apiKey.startsWith('AIza');

  // Modo Real activo
  static const bool useMock = verdadero;

  // --- ACTUALIZACIÓN: Endpoint estable v1 ---
  static const String endpoint = 'https://generativelanguage.googleapis.com/v1';
  
  static Uri get uri => Uri.parse(endpoint);

  // Funciones de utilidad para compatibilidad
  static Map<String, String> headers() => {
    'Content-Type': 'application/json',
  };
  
  static String dataUrlFromBytes(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Método de respaldo para evitar errores de compilación
  static Future<Map<String, dynamic>> postJson(Map<String, dynamic> body) async {
    debugPrint("Advertencia: postJson en OpenAiConfig llamado, pero la lógica está en AiDiagnosisService.");
    return {};
  }
}
