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
    // URL específica para la versión estable
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      // Simplificamos la estructura de las partes
      final List<Map<String, dynamic>> parts = [];
      
      // 1. Añadimos el texto primero
      parts.add({"text": _buildPrompt(animalCategory)});
      
      // 2. Añadimos las imágenes
      for (var photo in photos) {
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(photo)
          }
        });
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": parts}],
          "generationConfig": {
            "temperature": 0.2,
            "topP": 0.8,
            "topK": 40,
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        // Esto nos dirá exactamente qué dice Google en el cuerpo del error 400
        print("Cuerpo del error de Google: ${response.body}");
        throw 'Error de Google: ${response.statusCode} - Revisa la consola para detalles.';
      }

      final data = jsonDecode(response.body);
      final rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      
      Map<String, dynamic> aiJson = jsonDecode(rawText.trim().replaceAll('```json', '').replaceAll('```', ''));

      // Validación de seguridad
      if (aiJson['is_animal'] == false) throw 'VALIDATION_ERROR';

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
        photosBase64: photos.map((p) => base64Encode(p)).toList(),
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: aiJson['detectedSpecies'] ?? animalCategory,
        diseaseName: aiJson['diseaseName'],
        medicationName: aiJson['medicationName'],
        medicationDose: aiJson['medicationDose'],
        isPregnant: aiJson['isPregnant'] == true,
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Consultar veterinario',
        observations: aiJson['observations'] ?? 'Análisis completado.',
      );

    } catch (e) {
      debugPrint('🚨 ERROR: $e');
      throw e.toString();
    }
  }

  String _buildPrompt(String category) {
    return "Analiza las fotos de este $category. Responde SOLO en JSON con esta estructura: "
           '{"is_animal":true,"detectedSpecies":"string","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"foodRecommendation":"string","observations":"string"}';
  }
}
