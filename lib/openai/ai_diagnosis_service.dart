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
    
    // --- CORRECCIÓN: URL actualizada a la versión estable v1 ---
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
            "temperature": 0.2,
            "maxOutputTokens": 2048,
            "responseMimeType": "application/json"
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Verificación de estructura de respuesta de Google
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('La IA no devolvió candidatos. Verifica el contenido de la imagen.');
        }

        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpieza de JSON por si la IA incluye bloques de código Markdown
        String cleanJson = rawText;
        if (rawText.contains('```')) {
          cleanJson = rawText.split('```')[1].replaceFirst('json', '').trim();
        }

        final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

        // --- VALIDACIÓN DE SEGURIDAD ESTRICTA ---
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
        // Esto ayudará a diagnosticar si el 404 persiste por otra razón
        throw Exception('Error de Google Gemini (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 ERROR EN SERVICIO: $e');
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return """
    Eres un experto en visión veterinaria. Analiza las imágenes adjuntas con rigor científico.
    
    REGLA DE ORO DE SEGURIDAD:
    Si la imagen muestra una persona, un objeto inanimado, comida, o cualquier cosa que NO sea un animal, debes responder estrictamente con {"is_animal": false}.

    Si es un animal, responde en formato JSON con la siguiente estructura:
    {
      "is_animal": true,
      "detectedSpecies": "Especie detectada",
      "detectedBreed": "Raza detectada",
      "healthStatus": "bueno/regular/critico",
      "diseaseName": "Nombre de posible patología (si aplica)",
      "medicationName": "Principio activo recomendado",
      "medicationDose": "Dosis sugerida según peso visual estimado",
      "isPregnant": true/false,
      "pregnancyWeeks": número o null,
      "foodRecommendation": "Tipo de dieta sugerida",
      "observations": "Resumen profesional de lo observado"
    }

    Contexto del animal: $category.
    Responde ÚNICAMENTE el JSON puro.
    """;
  }
}
