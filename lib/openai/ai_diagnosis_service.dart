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
    
    // URL Corregida: Usamos gemini-1.5-flash y eliminamos errores de sintaxis
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'
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
            "temperature": 0.2, // Temperatura baja para mayor precisión en el filtro
            "maxOutputTokens": 2048,
            "responseMimeType": "application/json" // Forzamos formato JSON
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpieza de Markdown si Gemini lo incluye
        String cleanJson = rawText;
        if (rawText.contains('```')) {
          cleanJson = rawText.split('```')[1].replaceFirst('json', '').trim();
        }

        final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

        // --- VALIDACIÓN DE ANIMAL ---
        // Si la IA detecta que no es un animal, lanzamos un error específico
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
        throw Exception('Error de Google Gemini (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 ERROR EN SERVICIO: $e');
      rethrow; 
    }
  }

  String _buildPrompt(String category) {
    return """
    Eres un sistema de visión veterinaria profesional y estricto.
    
    TAREA DE VALIDACIÓN:
    - Primero, determina si la imagen contiene un ANIMAL. 
    - Si
