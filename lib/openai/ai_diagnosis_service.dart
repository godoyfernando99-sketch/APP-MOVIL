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
    
    if (!OpenAiConfig.isConfigured) {
      throw Exception('API Key no configurada');
    }

    final String apiKey = OpenAiConfig.apiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey'
    );

    try {
      List<Map<String, dynamic>> imageParts = photos.map((bytes) {
        return {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(bytes)
          }
        };
      }).toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [
              {"text": _buildPrompt(animalCategory)},
              ...imageParts
            ]
          }],
          "generationConfig": {
            "temperature": 0.1,
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('La IA no devolvió respuesta.');
        }

        String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
        
        // Limpiar JSON de bloques de código markdown
        String cleanJson = rawText.trim();
        if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```').firstWhere((s) => s.contains('{'), orElse: () => cleanJson);
          cleanJson = cleanJson.replaceAll('json', '').trim();
        }

        final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

        // --- VALIDACIÓN DE SEGURIDAD ---
        if (aiJson['is_animal'] == false) {
          throw Exception('VALIDATION_ERROR: No se detectó un animal en la imagen.');
        }

        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        // --- MAPEO SINCRONIZADO CON SCAN_MODELS.DART ---
        return ScanResult(
          id: now.millisecondsSinceEpoch.toString(),
          ownerId: '', 
          createdAt: now,
          updatedAt: now,
          animalId: animalId,
          animalCategory: animalCategory,
          mode: mode,
          microchipNumber: microchipNumber,
          photosBase64: photoB64,
          healthStatus: (aiJson['healthStatus'] ?? 'regular').toString(),
          detectedBreed: aiJson['detectedBreed']?.toString(),
          detectedSpecies: aiJson['detectedSpecies']?.toString(),
          diseaseName: aiJson['diseaseName']?.toString(),
          medicationName: aiJson['medicationName']?.toString(),
          medicationDose: aiJson['medicationDose']?.toString(),
          // Se usa la validación de tipos para evitar errores de cast
          isPregnant: aiJson['isPregnant'] is bool ? aiJson['isPregnant'] : null,
          pregnancyWeeks: int.tryParse(aiJson['pregnancyWeeks']?.toString() ?? ''),
          foodRecommendation: aiJson['foodRecommendation']?.toString(),
          observations: aiJson['observations']?.toString(),
        );
      } else {
        throw Exception('Error del servidor Google: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 ERROR DETALLADO: $e');
      if (e.toString().contains('VALIDATION_ERROR')) {
        throw e.toString().replaceAll('Exception: ', '');
      }
      throw 'Error de análisis: No se pudo procesar la respuesta de la IA.';
    }
  }

  String _buildPrompt(String category) {
    return """
    Eres un experto veterinario. Analiza la imagen y responde ÚNICAMENTE en JSON.
    Contexto del animal: $category
    
    Estructura JSON:
    {
      "is_animal": true,
      "detectedSpecies": "especie",
      "detectedBreed": "raza",
      "healthStatus": "bueno/regular/critico",
      "diseaseName": "nombre o null",
      "medicationName": "nombre o null",
      "medicationDose": "dosis o null",
      "isPregnant": false,
      "pregnancyWeeks": null,
      "foodRecommendation": "recomendación",
      "observations": "resumen profesional"
    }
    """;
  }
}
