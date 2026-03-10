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
      // CAMBIO CLAVE: Actualización al modelo 2.5 Flash Lite para 2026
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.5-flash-lite', 
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final imageParts = photos.map((bytes) => InlineDataPart('image/jpeg', bytes)).toList();

      // PROMPT: Se mantiene intacto según tus instrucciones
      final promptParts = [
        TextPart("""
          Actúa como un experto veterinario. Analiza las imágenes de este $animalCategory.
          ID Microchip NFC: ${microchipId ?? 'No detectado'}. Modo: $mode.

          INSTRUCCIONES OBLIGATORIAS:
          1. DETECCIÓN: Identifica especie y raza exacta.
          2. GRAVEDAD: Si detectas enfermedades graves, tumores o necesidad de cirugía, inicia 'healthStatus' con la palabra "URGENTE: ATENCIÓN VETERINARIA ESPECIAL".
          3. TRATAMIENTO: Si el usuario puede atenderlo, indica el nombre del MEDICAMENTO, la DOSIS exacta, la VÍA y el LUGAR de aplicación.
          4. PREVENCIÓN: Explica qué evitar para que no repita la enfermedad.
          5. GESTACIÓN: Si detectas embarazo, indica: número de crías, tiempo actual, DURACIÓN TOTAL y días para el parto.
          6. NUTRICIÓN: Recomienda alimento comercial y frecuencia.
          7. CONTROL: Setea 'rescanInterval' en 3.

          Responde ÚNICAMENTE en este formato JSON:
          {
            "animalType": "Especie",
            "breed": "Raza detectada",
            "healthStatus": "Diagnóstico",
            "preventionTips": ["tip 1"],
            "isPregnant": true/false,
            "offspringCount": "número",
            "gestationWeeks": "semanas",
            "totalGestationDuration": "duración",
            "daysUntilDelivery": 10,
            "rescanInterval": 3,
            "medicationDosage": "dosis",
            "medicationRoute": "vía",
            "applicationSite": "lugar",
            "suggestedFoodName": "Nombre Alimento",
            "foodRecommendation": "Guía"
          }
        """),
        ...imageParts,
      ];

      final response = await model.generateContent([Content.multi(promptParts)]);
      
      if (response.text == null) {
        throw Exception("La IA no devolvió una respuesta válida.");
      }

      final data = jsonDecode(response.text!);
      
      return ScanResult(
        id: "scan_${DateTime.now().millisecondsSinceEpoch}",
        animalType: data['animalType'] ?? animalCategory,
        healthStatus: data['healthStatus'] ?? "Análisis completado",
        preventionTips: List<String>.from(data['preventionTips'] ?? []),
        isPregnant: data['isPregnant'] ?? false,
        offspringCount: data['offspringCount'],
        gestationWeeks: data['gestationWeeks'],
        totalGestationDuration: data['totalGestationDuration'],
        daysUntilDelivery: data['daysUntilDelivery'],
        rescanInterval: data['rescanInterval'] ?? 3,
        medicationDosage: data['medicationDosage'],
        medicationRoute: data['medicationRoute'],
        applicationSite: data['applicationSite'],
        suggestedFoodName: data['suggestedFoodName'],
        foodRecommendation: data['foodRecommendation'],
        photos: photos,
        microchipId: microchipId,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint("🚨 Error en el servicio de IA: $e");
      rethrow;
    }
  }
}