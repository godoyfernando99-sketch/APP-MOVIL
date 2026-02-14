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
    
    // URL ESTABLE v1 - Confirmada sin restricciones en tu consola
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      // ESTRUCTURA BLINDADA: Organizamos texto e imágenes en el orden exacto que pide Gemini
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": _buildPrompt(animalCategory)},
              ...photos.map((photo) => {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Encode(photo)
                }
              }).toList(),
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "topP": 0.8,
          "topK": 40,
          "responseMimeType": "application/json"
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      // Verificación de estado con log detallado
      if (response.statusCode != 200) {
        debugPrint("🚨 ERROR GOOGLE (${response.statusCode}): ${response.body}");
        throw 'Error ${response.statusCode}: El servidor de Google no pudo procesar la solicitud.';
      }

      final data = jsonDecode(response.body);
      
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw 'La IA no devolvió ninguna respuesta. Intenta con otra foto.';
      }

      // Limpieza de JSON robusta
      String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      rawText = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      
      final Map<String, dynamic> aiJson = jsonDecode(rawText);

      // Validación de contenido
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
      debugPrint('🚨 ERROR CRÍTICO: $e');
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return "Actúa como un veterinario experto. Analiza las fotos de este $category. "
           "Genera un diagnóstico de salud y raza. "
           "Responde ÚNICAMENTE en formato JSON plano con esta estructura exacta: "
           '{"is_animal":true,"detectedSpecies":"string","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"foodRecommendation":"string","observations":"string"}';
  }
}
