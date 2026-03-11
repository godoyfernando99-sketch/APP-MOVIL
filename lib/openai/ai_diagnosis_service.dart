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
    bool isFollowUp = false,
  }) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.5-flash-lite', 
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      final List<Part> promptParts = [
        TextPart("""
          Actúa como un experto veterinario de élite. Analiza las imágenes.
          Seguimiento Evolutivo activo: ${isFollowUp ? 'SÍ' : 'NO'}.

          DEBES RESPONDER ÚNICAMENTE EN JSON CON ESTA ESTRUCTURA EXACTA:

          {
            "animalType": "Especie (Gato, Perro, etc)",
            "breed": "Raza o especie exacta",
            "isSane": true/false,
            "healthStatus": {
              "conditionName": "Nombre de la enfermedad o 'SANO'",
              "cause": "Causa exacta (bacteria, virus, hongo, etc)",
              "severity": "ALTA, MEDIA o BAJA",
              "isHighRisk": true/false
            },
            "treatment": {
              "medicineName": "Nombre del producto/fármaco",
              "type": "Oral, Inyección, Gotas o Pomada",
              "dosage": "Cantidad exacta (ml, mg, número de gotas o pastillas)",
              "frequency": "Cada cuántas horas",
              "duration": "Días totales",
              "applicationSite": "Lugar del cuerpo donde aplicar/inyectar",
              "careTips": "Cuidados para que no vuelva a suceder"
            },
            "vaccines": "Si está sano, lista de vacunas necesarias por edad/especie",
            "pregnancy": {
              "isPregnant": true/false,
              "weeks": "semanas",
              "days": "días",
              "months": "meses",
              "offspringCount": "número de crías",
              "totalDuration": "duración total embarazo especie",
              "daysUntilDelivery": 10
            },
            "nutrition": {
              "foodName": "Nombre del producto alimenticio sugerido",
              "recommendation": "Guía nutricional según su estado"
            }
          }

          INSTRUCCIONES:
          - Si 'healthStatus.severity' es ALTA, 'healthStatus.isHighRisk' debe ser true.
          - Si 'isSane' es true, omite 'healthStatus' y 'treatment', y llena 'vaccines' con detalle.
        """),
        ...photos.map((bytes) => InlineDataPart('image/jpeg', bytes)),
      ];

      final response = await model.generateContent([Content.multi(promptParts)]);
      final data = jsonDecode(response.text!);

      // Construimos el bloque de texto para el historial combinando los campos
      String report = "";
      if (data['isSane']) {
        report = "ESTADO: SANO\n\nVACUNAS RECOMENDADAS:\n${data['vaccines']}";
      } else {
        report = "ENFERMEDAD: ${data['healthStatus']['conditionName']}\n"
                 "CAUSA: ${data['healthStatus']['cause']}\n"
                 "GRAVEDAD: ${data['healthStatus']['severity']}\n\n"
                 "TRATAMIENTO:\n"
                 "- Medicamento: ${data['treatment']['medicineName']}\n"
                 "- Vía: ${data['treatment']['type']}\n"
                 "- Dosis: ${data['treatment']['dosage']}\n"
                 "- Frecuencia: ${data['treatment']['frequency']}\n"
                 "- Duración: ${data['treatment']['duration']}\n"
                 "- Aplicación: ${data['treatment']['applicationSite']}\n"
                 "- Cuidados: ${data['treatment']['careTips']}";
      }

      return ScanResult(
        id: "scan_${DateTime.now().millisecondsSinceEpoch}",
        animalType: data['animalType'],
        breed: data['breed'],
        healthStatus: report,
        isHighRisk: data['healthStatus']['isHighRisk'] ?? false,
        isPregnant: data['pregnancy']['isPregnant'] ?? false,
        offspringCount: data['pregnancy']['offspringCount']?.toString(),
        gestationWeeks: data['pregnancy']['weeks']?.toString(),
        daysUntilDelivery: data['pregnancy']['daysUntilDelivery'] ?? 0,
        totalGestationDuration: data['pregnancy']['totalDuration'],
        suggestedFoodName: data['nutrition']['foodName'],
        foodRecommendation: data['nutrition']['recommendation'],
        rescanInterval: 3, // Seguimiento cada 3 días
        photos: photos,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }
}