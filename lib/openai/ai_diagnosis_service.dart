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
    // 1. Verificar configuración - SI ESTO ES TRUE, NUNCA LLAMARÁ A GEMINI
    if (OpenAiConfig.useMock || !OpenAiConfig.isConfigured) {
      debugPrint('⚠️ ALERTA: Usando modo simulador. Verifica OpenAiConfig.useMock y tu API KEY.');
      return _mock(
        animalId: animalId, 
        animalCategory: animalCategory, 
        mode: mode, 
        microchipNumber: microchipNumber, 
        photos: photos
      );
    }

    final String apiKey = OpenAiConfig.apiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey'
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
              {"text": _buildPrompt(animalCategory, animalId)},
              ...imageParts
            ]
          }],
          "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 2048,
            "responseMimeType": "application/json", // Forzamos respuesta JSON
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpieza de Markdown mejorada
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        
        final Map<String, dynamic> aiJson = jsonDecode(text);
        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        String dosisFinal = aiJson['medicationDose']?.toString() ?? 'N/A';
        if (aiJson['injectionCm3'] != null && aiJson['injectionCm3'] != 'N/A') {
          dosisFinal += " | Aplicar: ${aiJson['injectionCm3']} cm³ (Inyectable)";
        }

        return ScanResult(
          id: _id(),
          ownerId: '', 
          createdAt: now,
          updatedAt: now,
          animalId: animalId,
          animalCategory: animalCategory,
          mode: mode,
          microchipNumber: microchipNumber,
          photosBase64: photoB64,
          healthStatus: (aiJson['healthStatus'] ?? 'regular').toString().toLowerCase(),
          detectedBreed: aiJson['detectedBreed']?.toString(),
          detectedSpecies: aiJson['detectedSpecies']?.toString(),
          diseaseName: aiJson['diseaseName']?.toString(),
          fractureDescription: aiJson['fractureDescription']?.toString(),
          medicationName: aiJson['medicationName']?.toString(),
          medicationDose: dosisFinal,
          isPregnant: aiJson['isPregnant'] is bool ? aiJson['isPregnant'] as bool : false,
          pregnancyWeeks: aiJson['pregnancyWeeks'] is num ? (aiJson['pregnancyWeeks'] as num).toInt() : null,
          foodRecommendation: "ALIMENTO: ${aiJson['foodRecommendation'] ?? 'No especificado'} | CUIDADOS: ${aiJson['specialCare'] ?? 'N/A'}",
          observations: aiJson['observations']?.toString(),
        );
      } else {
        print("❌ Error de API: ${response.body}");
        throw Exception('Error Gemini: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 ERROR CRÍTICO EN DIAGNÓSTICO: $e');
      // Si llegamos aquí, es porque algo falló en la conexión o el JSON y vuelve al simulador
      return _mock(
        animalId: animalId, 
        animalCategory: animalCategory, 
        mode: mode, 
        microchipNumber: microchipNumber, 
        photos: photos
      );
    }
  }

  String _buildPrompt(String category, String id) {
    return """
    ACTÚA COMO UN VETERINARIO EXPERTO.
    Analiza la imagen de este animal (Categoría sugerida: $category).
    
    TAREAS:
    1. IDENTIFICACIÓN: Determina la especie y la raza exacta según rasgos físicos.
    2. SALUD: Evalúa el estado general y detecta enfermedades visibles.
    3. TRATAMIENTO: Sugiere medicamento y dosis.

    DEBES RESPONDER EXCLUSIVAMENTE EN ESTE FORMATO JSON:
    {
      "detectedSpecies": "especie",
      "detectedBreed": "raza",
      "healthStatus": "buena/regular/mala",
      "diseaseName": "enfermedad",
      "fractureDescription": "descripción",
      "medicationName": "nombre",
      "medicationDose": "dosis",
      "injectionCm3": "cm3 o N/A",
      "isPregnant": true/false,
      "pregnancyWeeks": null o número,
      "foodRecommendation": "dieta",
      "specialCare": "cuidados",
      "observations": "resumen"
    }
    """;
  }

  ScanResult _mock({
    required String animalId,
    required String animalCategory,
    required String mode,
    required String? microchipNumber,
    required List<Uint8List> photos,
  }) {
    final now = DateTime.now();
    return ScanResult(
      id: _id(),
      ownerId: '',
      createdAt: now,
      updatedAt: now,
      animalId: animalId,
      animalCategory: animalCategory,
      mode: mode,
      microchipNumber: microchipNumber,
      photosBase64: photos.map((p) => base64Encode(p)).toList(),
      healthStatus: 'buena',
      detectedBreed: 'SIMULADOR ACTIVADO',
      detectedSpecies: 'Verifica tu API KEY',
      diseaseName: 'Simulación de diagnóstico',
      foodRecommendation: 'Asegúrate de poner useMock en false en openai_config.dart',
    );
  }

  String _id() => DateTime.now().millisecondsSinceEpoch.toString();
}
