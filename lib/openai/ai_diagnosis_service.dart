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
    
    // URL ESTABLE: Es la que mejor funciona tras configurar el consentimiento de OAuth
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final List<Map<String, dynamic>> parts = [];
      
      // 1. Agregamos el texto de instrucción
      parts.add({"text": _buildPrompt(animalCategory)});
      
      // 2. Agregamos todas las fotos capturadas
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
            "temperature": 0.1,
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 30));

      // Verificación de estado
      if (response.statusCode != 200) {
        debugPrint("🚨 ERROR GOOGLE (${response.statusCode}): ${response.body}");
        if (response.statusCode == 404) {
          throw 'Error 404: No se encuentra el modelo. Verifica que la API de Gemini esté habilitada en v1.';
        }
        throw 'Error ${response.statusCode}: El servidor de Google rechazó la petición.';
      }

      final data = jsonDecode(response.body);
      
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw 'La IA no pudo procesar la imagen. Intenta que la foto sea más clara.';
      }

      // Extraemos y limpiamos el texto para asegurar que sea un JSON válido
      String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      rawText = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      
      final Map<String, dynamic> aiJson = jsonDecode(rawText);

      // Validación de si es un animal
      if (aiJson['is_animal'] == false) throw 'No se detectó un animal en la imagen.';

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
        observations: aiJson['observations'] ?? 'Análisis completado exitosamente.',
      );

    } catch (e) {
      debugPrint('🚨 ERROR EN SERVICIO: $e');
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return "Actúa como un veterinario experto. Analiza las fotos de este $category. "
           "Responde ÚNICAMENTE en formato JSON plano con esta estructura: "
           '{"is_animal":true,"detectedSpecies":"string","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"foodRecommendation":"string","observations":"string"}';
  }
}
