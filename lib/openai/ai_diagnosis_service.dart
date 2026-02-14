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
            "temperature": 0.1, // Bajamos la temperatura para que sea más preciso
            "maxOutputTokens": 1000,
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('La IA no devolvió resultados.');
        }

        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // --- LIMPIEZA EXTREMA DEL JSON ---
        // Eliminamos posibles bloques de código markdown y espacios en blanco
        String cleanJson = rawText.trim();
        if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```').firstWhere((element) => element.contains('{'));
          cleanJson = cleanJson.replaceFirst('json', '').trim();
        }

        final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

        if (aiJson['is_animal'] == false) {
          throw Exception('VALIDATION_ERROR: Por favor, coloca una fotografía de un animal.');
        }

        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

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
          healthStatus: aiJson['healthStatus']?.toString().toLowerCase() ?? 'regular',
          detectedBreed: aiJson['detectedBreed']?.toString() ?? 'No identificada',
          detectedSpecies: aiJson['detectedSpecies']?.toString() ?? 'No identificada',
          diseaseName: aiJson['diseaseName']?.toString(),
          medicationName: aiJson['medicationName']?.toString(),
          medicationDose: aiJson['medicationDose']?.toString(),
          isPregnant: aiJson['isPregnant'] == true,
          pregnancyWeeks: (aiJson['pregnancyWeeks'] as num?)?.toInt(),
          foodRecommendation: aiJson['foodRecommendation']?.toString(),
          observations: aiJson['observations']?.toString(),
        );
      } else {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('🚨 ERROR DETALLADO: $e');
      // Si el error es de JSON, lanzamos un mensaje más claro
      if (e is FormatException) {
        throw Exception('Error de formato: La IA envió datos inválidos.');
      }
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return """
    Eres un experto veterinario. Analiza la imagen.
    Responde ESTRICTAMENTE en formato JSON plano, sin bloques de código, sin markdown y sin texto extra.
    
    Estructura requerida:
    {
      "is_animal": true/false,
      "detectedSpecies": "string",
      "detectedBreed": "string",
      "healthStatus": "bueno/regular/critico",
      "diseaseName": "string o null",
      "medicationName": "string o null",
      "medicationDose": "string o null",
      "isPregnant": false,
      "pregnancyWeeks": null,
      "foodRecommendation": "string",
      "observations": "string"
    }

    Contexto: $category.
    """;
  }
}