import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
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
      // CORRECCIÓN: Se accede a FirebaseAI sin el .instance
      final model = FirebaseAI.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final imageParts = photos.map((bytes) => InlineDataPart('image/jpeg', bytes)).toList();

      final promptParts = [
        TextPart("""
          Actúa como un experto veterinario. Analiza las imágenes de este $animalCategory.
          ID Microchip NFC: ${microchipId ?? 'No detectado'}. Modo: $mode.

          INSTRUCCIONES OBLIGATORIAS:
          1. DETECCIÓN: Identifica especie y raza exacta.
          2. GRAVEDAD: Si detectas enfermedades graves, tumores o necesidad de cirugía, inicia 'healthStatus' con la palabra "URGENTE: ATENCIÓN VETERINARIA ESPECIAL".
          3. TRATAMIENTO: Si el usuario puede atenderlo, indica el nombre del MEDICAMENTO, la DOSIS exacta, la VÍA (oral, ocular, inyección o pomada) y el LUGAR de aplicación.
          4. PREVENCIÓN: Explica qué evitar para que no repita la enfermedad.
          5. GESTACIÓN: Si detectas embarazo, indica: número de crías, tiempo actual (días/semanas), DURACIÓN TOTAL del embarazo y días para el parto.
          6. NUTRICIÓN: Recomienda el NOMBRE de un alimento comercial y frecuencia.
          7. CONTROL: Setea 'rescanInterval' en 3 para seguimiento obligatorio cada 3 días.

          Responde ÚNICAMENTE en este formato JSON:
          {
            "animalType": "Especie",
            "breed": "Raza detectada",
            "healthStatus": "Diagnóstico detallado",
            "preventionTips": ["tip 1", "tip 2", "prevención de recaída"],
            "isPregnant": true/false,
            "offspringCount": "número de crías",
            "gestationWeeks": "tiempo actual",
            "totalGestationDuration": "duración total del embarazo",
            "daysUntilDelivery": 10,
            "rescanInterval": 3,
            "medicationDosage": "cantidad exacta",
            "medicationRoute": "oral/ocular/inyección/pomada",
            "applicationSite": "lugar del cuerpo",
            "suggestedFoodName": "Nombre Alimento",
            "foodRecommendation": "Guía nutricional"
          }
        """),
        ...imageParts,
      ];

      final response = await model.generateContent([Content.multi(promptParts)]);
      
      final responseText = response.text;
      if (responseText == null) throw Exception("La IA no respondió.");

      final Map<String, dynamic> data = jsonDecode(responseText);
      
      return ScanResult(
        id: "scan_${DateTime.now().millisecondsSinceEpoch}",
        animalType: data['animalType'] ?? animalCategory,
        healthStatus: data['healthStatus'] ?? "Análisis completado",
        preventionTips: List<String>.from(data['preventionTips'] ?? []),
        isPregnant: data['isPregnant'] ?? (mode == 'gestation'),
        offspringCount: data['offspringCount'],
        gestationWeeks: data['gestationWeeks'],
        totalGestationDuration: data['totalGestationDuration'],
        daysUntilDelivery: data['daysUntilDelivery'],
        rescanInterval: data['rescanInterval'] ?? 3,
        medicationDosage: data['medicationDosage'],
        medicationRoute: data['medicationRoute'],
        applicationSite: data['applicationSite'],
        suggestedFoodName: data['suggestedFoodName'] ?? "Dieta Balanceada",
        foodRecommendation: data['foodRecommendation'] ?? "Sin instrucciones específicas",
        photos: photos,
        microchipId: microchipId,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      debugPrint("🚨 Error en Firebase AI: $e");
      rethrow;
    }
  }
}