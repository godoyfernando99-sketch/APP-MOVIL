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
    
    // CAMBIO 1: Usamos v1beta que es más flexible para el modelo Flash
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final List<Map<String, dynamic>> parts = [];
      parts.add({"text": _buildPrompt(animalCategory)});
      
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
            "temperature": 0.1, // Bajamos a 0.1 para que sea más preciso y no alucine
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 30));

      // CAMBIO 2: Si da 404 o 400, lanzamos un mensaje que explique el porqué
      if (response.statusCode != 200) {
        debugPrint("Cuerpo del error de Google: ${response.body}");
        if (response.statusCode == 404) {
          throw 'Error 404: Google no encuentra el modelo. Verifica que la API de Gemini esté habilitada.';
        }
        throw 'Error ${response.statusCode}: Verifica tu conexión y la API Key.';
      }

      final data = jsonDecode(response.body);
      
      // CAMBIO 3: Validación de candidatos para evitar errores de null
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw 'La IA no devolvió resultados. Intenta con otra foto.';
      }

      final rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      
      Map<String, dynamic> aiJson = jsonDecode(rawText.trim().replaceAll('```json', '').replaceAll('```', ''));

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
      rethrow; // Usamos rethrow para que la ScanPage capture el mensaje exacto
    }
  }

  String _buildPrompt(String category) {
    return "Analiza las fotos de este $category. Responde SOLO en JSON plano: "
           '{"is_animal":true,"detectedSpecies":"string","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"foodRecommendation":"string","observations":"string"}';
  }
}
