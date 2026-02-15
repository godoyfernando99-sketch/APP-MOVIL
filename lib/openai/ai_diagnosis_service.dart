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
    
    // URL ESTABLE V1
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      // Tomamos solo la primera foto y la convertimos a Base64 puro
      final String base64Image = base64Encode(photos.first);

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": "Analyze this $animalCategory and return a JSON with: healthStatus (good/regular/critical), detectedBreed, diseaseName, medicationName, medicationDose, foodRecommendation, and observations."},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "responseMimeType": "application/json"
        }
        // Quitamos los safetySettings por ahora para ver si eso está causando el 400
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint("🚨 ERROR DETALLADO DE GOOGLE: ${response.body}");
        throw 'Error ${response.statusCode}. El servidor no procesó la imagen.';
      }

      final data = jsonDecode(response.body);
      final String rawText = data['candidates'][0]['content']['parts'][0]['text'];
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
        photosBase64: [base64Image],
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: animalCategory,
        diseaseName: aiJson['diseaseName'] ?? 'No detectada',
        medicationName: aiJson['medicationName'] ?? 'N/A',
        medicationDose: aiJson['medicationDose'] ?? 'N/A',
        isPregnant: false,
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Consultar veterinario',
        observations: aiJson['observations'] ?? 'Análisis completado.',
      );

    } catch (e) {
      debugPrint('🚨 FALLO TOTAL: $e');
      rethrow;
    }
  }
}
