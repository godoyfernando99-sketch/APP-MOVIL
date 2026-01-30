import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAiConfig {
  // Tu llave de Google Gemini pegada directamente para que funcione siempre
  static const String apiKey = 'AIzaSyConmf0PN79jBFkNkHZRKMym2KcTNPI4gI';

  // Verifica que la llave esté puesta y sea de Google
  static bool get isConfigured => apiKey.isNotEmpty && apiKey.startsWith('AIza');

  // Modo Real activo (useMock en false)
  static const bool useMock = false;

  // Nota: Ya no necesitamos 'endpoint' ni 'headers' porque 
  // Gemini se conecta de forma distinta en el DiagnosisService.
}

  static String dataUrlFromBytes(Uint8List bytes) => 'data:image/jpeg;base64,${base64Encode(bytes)}';

  static Future<Map<String, dynamic>> postJson(Map<String, dynamic> body) async {
    final res = await http.post(uri, headers: headers(), body: utf8.encode(jsonEncode(body)));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('OpenAI error (${res.statusCode}): ${res.body}');
      throw Exception('OpenAI request failed');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected OpenAI response');
  }
}
