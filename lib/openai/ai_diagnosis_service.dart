import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Asegúrate de tener 'http' en pubspec.yaml
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
    // 1. Verificar si usamos el simulador o si no hay llave configurada
    if (OpenAiConfig.useMock || !OpenAiConfig.isConfigured) {
      debugPrint('Usando modo simulador o falta API Key de Gemini.');
      return _mock(
        animalId: animalId, 
        animalCategory: animalCategory, 
        mode: mode, 
        microchipNumber: microchipNumber, 
        photos: photos
      );
    }

    // 2. Preparar la conexión con Google Gemini
    final String apiKey = OpenAiConfig.apiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'
    );

    try {
      // Convertir las fotos a formato Base64 que entiende Google
      List<Map<String, dynamic>> imageParts = photos.map((bytes) {
        return {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(bytes)
          }
        };
      }).toList();

      // 3. Enviar la petición a la IA
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
            "temperature": 0.3, // Menos aleatoriedad, más precisión médica
            "maxOutputTokens": 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Limpiar el formato Markdown si la IA lo incluye
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        
        final Map<String, dynamic> json = jsonDecode(text);

        final photoB64 = photos.map((p) => base64Encode(p)).toList();
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
          photosBase64: photoB64,
          healthStatus: (json['healthStatus'] ?? 'regular').toString(),
          diseaseName: json['diseaseName']?.toString(),
          fractureDescription: json['fractureDescription']?.toString(),
          medicationName: json['medicationName']?.toString(),
          medicationDose: json['medicationDose']?.toString(),
          isPregnant: json['isPregnant'] is bool ? json['isPregnant'] as bool : null,
          pregnancyWeeks: json['pregnancyWeeks'] is num ? (json['pregnancyWeeks'] as num).toInt() : null,
          foodRecommendation: json['foodRecommendation']?.toString(),
        );
      } else {
        throw Exception('Error de Google Gemini: ${response.body}');
      }
    } catch (e) {
      debugPrint('Fallo en diagnóstico real, saltando a mock: $e');
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
    Eres un veterinario experto. Analiza estas 3 fotos de un $category (ID: $id).
    Responde estrictamente en formato JSON plano.
    
    Estructura JSON:
    {
      "healthStatus": "buena" | "regular" | "mala",
      "diseaseName": "Nombre de enfermedad detectada o null",
      "fractureDescription": "Descripción de fractura o lesión ósea o null",
      "medicationName": "Sugerencia de medicamento o null",
      "medicationDose": "Dosis cualitativa o null",
      "isPregnant": true | false | null,
      "pregnancyWeeks": número o null,
      "foodRecommendation": "Recomendación de alimentación"
    }
    
    Analiza pelaje, postura, ojos y abdomen. Sé específico.
    """;
  }

  // --- MANTENEMOS TU FUNCIÓN MOCK ORIGINAL POR SI FALLA EL INTERNET ---
  ScanResult _mock({
    required String animalId,
    required String animalCategory,
    required String mode,
    required String? microchipNumber,
    required List<Uint8List> photos,
  }) {
    final rnd = Random();
    final photoB64 = photos.map((p) => base64Encode(p)).toList();
    final now = DateTime.now();
    final healthRoll = rnd.nextInt(100);
    final health = healthRoll < 60 ? 'buena' : (healthRoll < 85 ? 'regular' : 'mala');
    
    return ScanResult(
      id: _id(),
      ownerId: '',
      createdAt: now,
      updatedAt: now,
      animalId: animalId,
      animalCategory: animalCategory,
      mode: mode,
      microchipNumber: mode == 'chip' ? (microchipNumber ?? 'DEMO-CHIP') : null,
      photosBase64: photoB64,
      healthStatus: health,
      diseaseName: health == 'buena' ? null : 'Simulación por falta de conexión',
      foodRecommendation: 'Mantener hidratación y forraje fresco.',
    );
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}
