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
    
    // 1. Verificación de Seguridad
    if (!OpenAiConfig.isConfigured) {
      throw Exception('La API Key no está configurada correctamente en OpenAiConfig');
    }

    final String apiKey = OpenAiConfig.apiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey'
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
            "temperature": 0.4,
            "maxOutputTokens": 2048,
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extraer el texto de la respuesta de Gemini
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // LIMPIEZA EXTREMA DEL JSON
        String cleanJson = rawText;
        if (rawText.contains('```')) {
          cleanJson = rawText.split('```')[1].replaceFirst('json', '').trim();
        }

        final Map<String, dynamic> aiJson = jsonDecode(cleanJson);
        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        return ScanResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          ownerId: '', 
          createdAt: now,
          updatedAt: now,
          animalId: animalId,
          animalCategory: animalCategory,
          mode: mode,
          microchipNumber: microchipNumber,
          photosBase64: photoB64,
          healthStatus: aiJson['healthStatus']?.toString().toLowerCase() ?? 'regular',
          detectedBreed: aiJson['detectedBreed']?.toString() ?? 'Raza no identificada',
          detectedSpecies: aiJson['detectedSpecies']?.toString() ?? 'Especie no identificada',
          diseaseName: aiJson['diseaseName']?.toString(),
          medicationName: aiJson['medicationName']?.toString(),
          medicationDose: aiJson['medicationDose']?.toString(),
          isPregnant: aiJson['isPregnant'] == true,
          pregnancyWeeks: (aiJson['pregnancyWeeks'] as num?)?.toInt(),
          foodRecommendation: aiJson['foodRecommendation']?.toString(),
          observations: aiJson['observations']?.toString(),
        );
      } else {
        // Si la API responde error (ej: 403, 400), lo veremos aquí
        throw Exception('Error de Google Gemini (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // YA NO REGRESAMOS EL MOCK. Ahora lanzamos el error real para saber qué pasa.
      debugPrint('🚨 ERROR REAL: $e');
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return """
    Eres un experto Veterinario. Analiza las imágenes.
    Debes identificar la RAZA y ESPECIE exacta.
    Responde ÚNICAMENTE en este formato JSON:
    {
      "detectedSpecies": "especie",
      "detectedBreed": "raza",
      "healthStatus": "buena/regular/mala",
      "diseaseName": "enfermedad detectada",
      "medicationName": "medicamento",
      "medicationDose": "dosis",
      "isPregnant": true/false,
      "pregnancyWeeks": semanas o null,
      "foodRecommendation": "dieta",
      "observations": "notas adicionales"
    }
    """;
  }
}
