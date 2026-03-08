import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:scanneranimal/app/history/scan_models.dart';

class AiDiagnosisService {
  const AiDiagnosisService();

  Future<ScanResult> diagnose({
    required String animalId,
    required String animalCategory,
    required String mode,
    required List<Uint8List> photos,
    String? microchipId,
  }) async {
    try {
      // 1. Inicializar el modelo (Gemini 1.5 Flash es ideal por su rapidez y costo)
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json', // Forzamos respuesta en JSON
        ),
      );

      // 2. Preparar las imágenes para la IA
      final imageParts = photos.map((bytes) => DataPart('image/jpeg', bytes)).toList();

      // 3. El Prompt (Instrucciones reales para la IA)
      final prompt = [
        Content.multi([
          ...imageParts,
          TextPart("""
            Actúa como un experto veterinario especializado en $animalCategory.
            Analiza las imágenes adjuntas. El animal tiene el ID de microchip: ${microchipId ?? 'No detectado'}.
            El modo de análisis solicitado es: $mode (salud o gestación).

            Devuelve estrictamente un objeto JSON con esta estructura exacta:
            {
              "animalType": "Especie y raza detectada",
              "healthStatus": "Diagnóstico corto de salud",
              "preventionTips": ["tip 1", "tip 2", "tip 3"],
              "isPregnant": ${mode == 'gestation'},
              "offspringCount": "estimación de crías si aplica o N/A",
              "gestationWeeks": "semanas estimadas si aplica o N/A",
              "daysUntilDelivery": 0,
              "rescanInterval": 7,
              "medicationDays": [1, 5],
              "suggestedFoodName": "Nombre de un alimento comercial o dieta específica",
              "foodRecommendation": "Explicación detallada de por qué este alimento y cómo darlo"
            }
            No añadas texto fuera del JSON.
          """),
        ])
      ];

      // 4. Llamada real a la IA
      final response = await model.generateContent(prompt);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception("La IA no devolvió ninguna respuesta.");
      }

      // 5. Convertir la respuesta de la IA en nuestro modelo ScanResult
      final Map<String, dynamic> data = jsonDecode(responseText);
      
      // Añadimos los datos que la IA no conoce (como las fotos originales)
      return ScanResult(
        id: "scan_${DateTime.now().millisecondsSinceEpoch}",
        animalType: data['animalType'] ?? animalCategory,
        healthStatus: data['healthStatus'] ?? "Análisis completado",
        preventionTips: List<String>.from(data['preventionTips'] ?? []),
        isPregnant: data['isPregnant'] ?? (mode == 'gestation'),
        offspringCount: data['offspringCount'],
        gestationWeeks: data['gestationWeeks'],
        daysUntilDelivery: data['daysUntilDelivery'],
        rescanInterval: data['rescanInterval'] ?? 7,
        medicationDays: List<int>.from(data['medicationDays'] ?? []),
        suggestedFoodName: data['suggestedFoodName'] ?? "Dieta Balanceada",
        foodRecommendation: data['foodRecommendation'] ?? "Sin instrucciones específicas",
        photos: photos,
        microchipId: microchipId,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      debugPrint("🚨 Error Real en Vertex AI: $e");
      rethrow;
    }
  }
}