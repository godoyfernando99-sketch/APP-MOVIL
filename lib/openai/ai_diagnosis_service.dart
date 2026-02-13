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
    // 1. Verificar configuración
    if (OpenAiConfig.useMock || !OpenAiConfig.isConfigured) {
      debugPrint('Usando modo simulador.');
      return _mock(
        animalId: animalId, 
        animalCategory: animalCategory, 
        mode: mode, 
        microchipNumber: microchipNumber, 
        photos: photos
      );
    }

    final String apiKey = OpenAiConfig.apiKey;
    // USAMOS GEMINI-1.5-PRO PARA MÁXIMA PRECISIÓN MÉDICA Y VETERINARIA
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
            "temperature": 0.4, // Un poco más bajo para evitar alucinaciones en la raza
            "maxOutputTokens": 2048,
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpiar el Markdown de la respuesta
        text = text.replaceAll(RegExp(r'```json|```'), '').trim();
        
        final Map<String, dynamic> aiJson = jsonDecode(text);
        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        // Combinamos la dosis con los CM3
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
          // NUEVOS CAMPOS: Capturamos lo que la IA "adivinó"
          detectedBreed: aiJson['detectedBreed']?.toString(),
          detectedSpecies: aiJson['detectedSpecies']?.toString(),
          
          diseaseName: aiJson['diseaseName']?.toString(),
          fractureDescription: aiJson['fractureDescription']?.toString(),
          medicationName: aiJson['medicationName']?.toString(),
          medicationDose: dosisFinal,
          isPregnant: aiJson['isPregnant'] is bool ? aiJson['isPregnant'] as bool : false,
          pregnancyWeeks: aiJson['pregnancyWeeks'] is num ? (aiJson['pregnancyWeeks'] as num).toInt() : null,
          foodRecommendation: "ALIMENTO: ${aiJson['foodRecommendation']} | CUIDADOS: ${aiJson['specialCare']}",
          observations: aiJson['observations']?.toString(),
        );
      } else {
        throw Exception('Error Gemini: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en diagnóstico: $e');
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
    ACTÚA COMO UN VETERINARIO PATÓLOGO Y EXPERTO EN ZOOTECNIA.
    Analiza las fotos adjuntas para este animal de la categoría: $category.
    
    TAREAS OBLIGATORIAS:
    1. IDENTIFICACIÓN: Determina la especie y la raza exacta del animal basándote en sus rasgos físicos (ej. Perro - Golden Retriever, Vaca - Holando Argentino).
    2. DIAGNÓSTICO: Identifica enfermedades específicas (Aftosa, Mastitis, Moquillo, Brucelosis, etc.) o lesiones visibles.
    3. PREÑEZ: En hembras, analiza signos de gestación (asimetría, ubre, vulva).
    4. TRATAMIENTO: Medicamento, dosis y cm³ si es inyectable.

    RESPONDE EXCLUSIVAMENTE EN JSON PLANO:
    {
      "detectedSpecies": "Especie identificada",
      "detectedBreed": "Raza identificada",
      "healthStatus": "buena" | "regular" | "mala",
      "diseaseName": "Nombre de la enfermedad o 'Ninguna'",
      "fractureDescription": "Descripción de lesiones",
      "medicationName": "Medicamento",
      "medicationDose": "Dosis",
      "injectionCm3": "cm3 o N/A",
      "isPregnant": true/false,
      "pregnancyWeeks": número o null,
      "foodRecommendation": "Dieta sugerida",
      "specialCare": "Instrucciones de manejo",
      "observations": "Breve resumen del hallazgo visual"
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
      detectedBreed: 'Raza Simulada',
      detectedSpecies: 'Especie Simulada',
      diseaseName: 'Simulación de diagnóstico',
      foodRecommendation: 'Mantener dieta balanceada.',
    );
  }

  String _id() => DateTime.now().millisecondsSinceEpoch.toString();
}
