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
          "generationConfig": {"temperature": 0.1, "responseMimeType": "application/json"}
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) throw 'Error de Google: ${response.statusCode}';

      final data = jsonDecode(response.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      
      // LOG PARA DEPURAR: Esto aparecerá en tu consola de VS Code/Android Studio
      debugPrint('--- RESPUESTA DE LA IA ---');
      debugPrint(rawText);
      debugPrint('--------------------------');

      // Limpieza manual por si acaso
      String cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      Map<String, dynamic> aiJson;
      
      try {
        aiJson = jsonDecode(cleanJson);
      } catch (e) {
        // Si el JSON falla, intentamos extraer lo que haya entre llaves
        final match = RegExp(r'\{.*\}', dotAll: true).stringMatch(cleanJson);
        if (match != null) {
          aiJson = jsonDecode(match);
        } else {
          throw 'La IA no envió un formato válido.';
        }
      }

      final now = DateTime.now();

      // CREACIÓN DEL OBJETO CON VALORES POR DEFECTO PARA EVITAR CRASHES
      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        ownerId: 'user_test', // Ponemos un ID temporal
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
      // Esto es lo que ves en el cartel rojo. Ahora nos dirá MÁS INFO.
      throw 'Error: ${e.toString().split('\n')[0]}'; 
    }
  }

  String _buildPrompt(String category) {
    return "Analiza estas fotos de $category. Responde SOLO en JSON plano con esta estructura: "
           '{"is_animal":true,"detectedSpecies":"string","detectedBreed":"string","healthStatus":"bueno/regular/critico",'
           '"diseaseName":"string","medicationName":"string","medicationDose":"string","isPregnant":false,"pregnancyWeeks":null,'
           '"foodRecommendation":"string","observations":"string"}';
  }
}
