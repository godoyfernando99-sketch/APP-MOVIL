import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/openai/openai_config.dart';

class AiDiagnosisService {
  const AiDiagnosisService();

  Future<ScanResult> diagnose({
    required String animalId,
    required String animalCategory, // Aquí debe venir "perro", "vaca", etc.
    required String mode,
    String? microchipNumber,
    required List<Uint8List> photos,
  }) async {
    
    final String apiKey = OpenAiConfig.apiKey;
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

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
          "temperature": 0.1,
          "responseMimeType": "application/json"
        },
        // ESTO EVITA QUE GOOGLE BLOQUEE FOTOS DE HERIDAS O ANIMALES EN MAL ESTADO
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
        ]
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        debugPrint("🚨 ERROR DE GOOGLE: ${response.body}");
        throw 'Error ${response.statusCode}: El servidor rechazó la imagen.';
      }

      final data = jsonDecode(response.body);
      
      // Verificamos si la respuesta fue bloqueada por seguridad a pesar de los settings
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        if (data['promptFeedback'] != null) {
          throw 'La imagen fue bloqueada por filtros de seguridad de Google.';
        }
        throw 'La IA no pudo generar una respuesta.';
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
        diseaseName: aiJson['diseaseName'],
        medicationName: aiJson['medicationName'],
        medicationDose: aiJson['medicationDose'],
        isPregnant: aiJson['isPregnant'] == true,
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Consultar veterinario',
        observations: aiJson['observations'] ?? 'Análisis completado exitosamente.',
      );

    } catch (e) {
      debugPrint('🚨 FALLO EN DIAGNÓSTICO: $e');
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return "Actúa como un veterinario experto. Analiza la foto de este $category. "
           "Si ves síntomas de enfermedad o desnutrición, descríbelos profesionalmente. "
           "Responde ÚNICAMENTE en JSON plano: "
           '{"is_animal":true,"detectedSpecies":"$category","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"foodRecommendation":"string","observations":"string"}';
  }
}
