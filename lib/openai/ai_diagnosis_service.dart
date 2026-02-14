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
    // Usamos v1 que es la estable
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
        
        // Extraer el texto de forma segura
        String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
        
        // Limpiar el texto por si vienen comillas o bloques de código
        String cleanJson = rawText.trim();
        if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```').firstWhere((s) => s.contains('{'), orElse: () => cleanJson);
          cleanJson = cleanJson.replaceAll('json', '').trim();
        }

        final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

        // --- VALIDACIÓN DE ANIMAL ---
        if (aiJson['is_animal'] == false) {
          throw Exception('VALIDATION_ERROR: No se detectó un animal en la imagen.');
        }

        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        // --- MAPEO ULTRA-SEGURO (Evita que la app explote si falta un campo) ---
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
          healthStatus: (aiJson['healthStatus'] ?? 'regular').toString().toLowerCase(),
          detectedBreed: (aiJson['detectedBreed'] ?? 'No identificada').toString(),
          detectedSpecies: (aiJson['detectedSpecies'] ?? 'No identificada').toString(),
          diseaseName: aiJson['diseaseName']?.toString() ?? 'Ninguna detectada',
          medicationName: aiJson['medicationName']?.toString() ?? 'N/A',
          medicationDose: aiJson['medicationDose']?.toString() ?? 'N/A',
          isPregnant: aiJson['isPregnant'] == true,
          pregnancyWeeks: int.tryParse(aiJson['pregnancyWeeks']?.toString() ?? '0') ?? 0,
          foodRecommendation: aiJson['foodRecommendation']?.toString() ?? 'Dieta balanceada',
          observations: aiJson['observations']?.toString() ?? 'Sin observaciones adicionales',
        );
      } else {
        throw Exception('Error del servidor Google: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 ERROR CRÍTICO: $e');
      // Esto es lo que ves en el SnackBar rojo
      if (e.toString().contains('VALIDATION_ERROR')) {
        throw e.toString().replaceAll('Exception: ', '');
      }
      throw 'Error de análisis: Verifica la imagen e intenta de nuevo.';
    }
  }

  String _buildPrompt(String category) {
    return """
    Eres un experto veterinario. Analiza la imagen y responde SOLO en JSON.
    Contexto: $category
    
    Estructura (rellena con "N/A" si no aplica):
    {
      "is_animal": true,
      "detectedSpecies": "especie",
      "detectedBreed": "raza",
      "healthStatus": "bueno/regular/critico",
      "diseaseName": "nombre o N/A",
      "medicationName": "nombre o N/A",
      "medicationDose": "dosis o N/A",
      "isPregnant": false,
      "pregnancyWeeks": 0,
      "foodRecommendation": "recomendación",
      "observations": "resumen"
    }
    """;
  }
}
