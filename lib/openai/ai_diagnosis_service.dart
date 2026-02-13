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
            "temperature": 0.5, // PERMITE DEDUCCIÓN DE SIGNOS SUTILES
            "maxOutputTokens": 2048,
          }
        }),
      ).timeout(const Duration(seconds: 45)); // MÁS TIEMPO PARA ANÁLISIS PROFUNDO

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpiar el Markdown de la respuesta
        text = text.replaceAll(RegExp(r'```json|```'), '').trim();
        
        final Map<String, dynamic> aiJson = jsonDecode(text);
        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        // Combinamos la dosis con los CM3 para la visualización
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
          diseaseName: aiJson['diseaseName']?.toString(),
          fractureDescription: aiJson['fractureDescription']?.toString(),
          medicationName: aiJson['medicationName']?.toString(),
          medicationDose: dosisFinal,
          isPregnant: aiJson['isPregnant'] is bool ? aiJson['isPregnant'] as bool : false,
          pregnancyWeeks: aiJson['pregnancyWeeks'] is num ? (aiJson['pregnancyWeeks'] as num).toInt() : null,
          foodRecommendation: "ALIMENTO: ${aiJson['foodRecommendation']} | CUIDADOS: ${aiJson['specialCare']}",
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
    ACTÚA COMO UN VETERINARIO PATÓLOGO Y EXPERTO EN REPRODUCCIÓN ANIMAL.
    Analiza las fotos de este $category (ID: $id).
    
    TAREAS OBLIGATORIAS:
    1. DIAGNÓSTICO: Identifica enfermedades específicas de la lista: Aftosa, Mastitis, Parvovirus, Moquillo, Brucelosis, Rabia, Parásitos, etc.
    2. PREÑEZ: Analiza asimetría de flanco derecho, llenado de ubre y cambios vulvares. Detecta preñez incluso si NO hay bulto evidente.
    3. TRATAMIENTO: Provee nombre del medicamento, dosis exacta según peso visual estimado y, si es inyección, indica los cm³ exactos.
    4. MANEJO: Indica alimento recomendado y cuidados (aislamiento, limpieza).

    RESPONDE ÚNICAMENTE EN JSON PLANO:
    {
      "healthStatus": "buena" | "regular" | "mala",
      "diseaseName": "Nombre de la enfermedad o 'Ninguna'",
      "fractureDescription": "Descripción de lesiones o fracturas",
      "medicationName": "Medicamento recomendado",
      "medicationDose": "Dosis (ej: 500mg cada 8h)",
      "injectionCm3": "Cantidad en cm3 si es inyectable, sino N/A",
      "isPregnant": true/false,
      "pregnancyWeeks": número de semanas estimado,
      "foodRecommendation": "Dieta específica para recuperación",
      "specialCare": "Instrucciones de aislamiento y manejo"
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
      diseaseName: 'Simulación de diagnóstico',
      foodRecommendation: 'Mantener dieta balanceada.',
    );
  }

  String _id() => DateTime.now().millisecondsSinceEpoch.toString();
}
