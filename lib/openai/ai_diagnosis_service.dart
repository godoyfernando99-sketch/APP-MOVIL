import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
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
              {"text": _buildPrompt(animalCategory, animalId)},
              ...imageParts
            ]
          }],
          "generationConfig": {
            "temperature": 0.2, // Reducido ligeramente para más consistencia
            "maxOutputTokens": 1024,
          }
        }),
      ).timeout(const Duration(seconds: 30)); // Añadido timeout por seguridad

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpiar el Markdown de la respuesta de la IA
        text = text.replaceAll(RegExp(r'```json|```'), '').trim();
        
        final Map<String, dynamic> aiJson = jsonDecode(text);
        final photoB64 = photos.map((p) => base64Encode(p)).toList();
        final now = DateTime.now();

        // Creamos el objeto usando el constructor del modelo corregido
        return ScanResult(
          id: _id(),
          ownerId: '', // Se llena en el controlador antes de guardar
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
          medicationDose: aiJson['medicationDose']?.toString(),
          isPregnant: aiJson['isPregnant'] is bool ? aiJson['isPregnant'] as bool : null,
          pregnancyWeeks: aiJson['pregnancyWeeks'] is num ? (aiJson['pregnancyWeeks'] as num).toInt() : null,
          foodRecommendation: aiJson['foodRecommendation']?.toString() ?? 'Consultar con un veterinario local.',
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
    Eres un veterinario experto. Analiza las fotos de este $category (ID: $id).
    Detecta signos de enfermedades, fracturas visibles o estado de gestación.
    Responde ÚNICAMENTE en formato JSON plano.
    
    Estructura requerida:
    {
      "healthStatus": "buena" | "regular" | "mala",
      "diseaseName": "Nombre",
      "fractureDescription": "Detalle",
      "medicationName": "Sugerencia",
      "medicationDose": "Dosis",
      "isPregnant": boolean,
      "pregnancyWeeks": number,
      "foodRecommendation": "Texto"
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
