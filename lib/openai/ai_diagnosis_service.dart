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
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      List<Map<String, dynamic>> imageParts = photos.map((bytes) => {
        "inline_data": {"mime_type": "image/jpeg", "data": base64Encode(bytes)}
      }).toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": _buildPrompt(animalCategory)}, ...imageParts]}],
          "generationConfig": {
            "temperature": 0.1, 
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) throw 'Error de Google: ${response.statusCode}';

      final data = jsonDecode(response.body);
      
      // Verificación de seguridad por si Google bloquea la imagen
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw 'Google bloqueó la imagen por seguridad o falta de claridad.';
      }

      String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      
      debugPrint('--- RESPUESTA CRUDA DE LA IA ---');
      debugPrint(rawText);

      // Limpieza de JSON
      String cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      Map<String, dynamic> aiJson = jsonDecode(cleanJson);

      // VALIDACIÓN CRÍTICA: ¿Es realmente un animal?
      if (aiJson['is_animal'] == false) {
        throw 'VALIDATION_ERROR'; // Esto lo atrapará la ScanPage que arreglamos antes
      }

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
        healthStatus: (aiJson['healthStatus'] ?? 'regular').toString(),
        detectedBreed: (aiJson['detectedBreed'] ?? 'Desconocida').toString(),
        detectedSpecies: (aiJson['detectedSpecies'] ?? animalCategory).toString(),
        diseaseName: aiJson['diseaseName']?.toString(),
        medicationName: aiJson['medicationName']?.toString(),
        medicationDose: aiJson['medicationDose']?.toString(),
        isPregnant: aiJson['isPregnant'] == true,
        pregnancyWeeks: int.tryParse(aiJson['pregnancyWeeks']?.toString() ?? ''),
        foodRecommendation: aiJson['foodRecommendation']?.toString() ?? 'Consultar veterinario',
        observations: aiJson['observations']?.toString() ?? 'Análisis completado.',
      );

    } catch (e) {
      debugPrint('🚨 ERROR EN SERVICIO: $e');
      if (e.toString().contains('VALIDATION_ERROR')) {
        throw 'VALIDATION_ERROR';
      }
      throw 'Error: ${e.toString().split('\n')[0]}'; 
    }
  }

  String _buildPrompt(String category) {
    return "Eres un experto veterinario. Analiza las fotos de este $category e identifica: "
           "1. Si hay un animal presente (is_animal: true/false). "
           "2. Especie y Raza. "
           "3. Estado de salud (bueno, regular, critico). "
           "4. Si detectas enfermedades, indica nombre y posible medicación/dosis. "
           "5. Recomendación alimenticia. "
           "Responde ESTRICTAMENTE en este formato JSON: "
           '{"is_animal":true,"detectedSpecies":"string","detectedBreed":"string","healthStatus":"string",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"pregnancyWeeks":null,'
           '"foodRecommendation":"string","observations":"string"}';
  }
}
