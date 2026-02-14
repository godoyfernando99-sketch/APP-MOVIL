import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/openai/openai_config.dart';

class AiDiagnosisService {
  const AiDiagnosisService();

  Future<ScanResult> diagnose({
    required String animalId,
    required String animalCategory,
    required String mode,
    String? microchipNumber,
    required List<Uint8List> photos,
  }) async {
    final String apiKey = OpenAiConfig.apiKey;
    // Usamos el modelo v1beta que suele ser más permisivo con los filtros en producción
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final Uint8List photoToProcess = photos.first;

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": _buildPrompt(animalCategory)},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Encode(photoToProcess)
                }
              },
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "topP": 0.8,
          "topK": 40,
          "maxOutputTokens": 1000,
          "responseMimeType": "application/json"
        },
        // DESACTIVACIÓN TOTAL DE FILTROS PARA CASOS VETERINARIOS
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_CIVIC_INTEGRITY", "threshold": "BLOCK_NONE"}
        ]
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint("🚨 GOOGLE ERROR: ${response.body}");
        throw 'Error de servidor (${response.statusCode}). Reintenta.';
      }

      final data = jsonDecode(response.body);
      
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw 'La IA no pudo procesar esta imagen específica. Intenta con otra toma.';
      }

      String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      rawText = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      
      final Map<String, dynamic> aiJson = jsonDecode(rawText);
      final now = DateTime.now();

      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        ownerId: 'user_test',
        createdAt: now,
        updatedAt: now,
        animalId: animalId,
        animalCategory: animalCategory,
        mode: mode,
        microchipNumber: microchipNumber,
        photosBase64: [base64Encode(photoToProcess)],
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: aiJson['detectedSpecies'] ?? animalCategory,
        diseaseName: aiJson['diseaseName'] ?? 'No detectada',
        medicationName: aiJson['medicationName'] ?? 'Consulte al veterinario',
        medicationDose: aiJson['medicationDose'] ?? 'Bajo supervisión',
        isPregnant: aiJson['isPregnant'] == true,
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Dieta balanceada',
        observations: aiJson['observations'] ?? 'Análisis realizado.',
      );

    } catch (e) {
      debugPrint('🚨 ERROR EN SERVICIO: $e');
      rethrow;
    }
  }

  String _buildPrompt(String category) {
    return "Eres un experto en salud animal. Analiza este $category. "
           "Si detectas patologías, descríbelas para fines educativos. "
           "Responde SIEMPRE en JSON plano con esta estructura: "
           '{"is_animal":true,"detectedSpecies":"$category","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"foodRecommendation":"string","observations":"string"}';
  }
}
