import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAiConfig {
  static const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

  static bool get isConfigured => apiKey.isNotEmpty && endpoint.isNotEmpty;

  static Uri get uri => Uri.parse(endpoint);

  static Map<String, String> headers() => {
    'content-type': 'application/json; charset=utf-8',
    'authorization': 'Bearer $apiKey',
  };

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
