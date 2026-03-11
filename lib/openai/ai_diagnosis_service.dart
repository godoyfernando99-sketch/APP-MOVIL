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
          ID Animal detectado (si aplica): ${microchipId ?? 'N/A'}.

          DEBES RESPONDER ÚNICAMENTE EN JSON CON ESTA ESTRUCTURA EXACTA:

          {
            "animalType": "Especie (Perro, Gato, Vaca, Cabra, Mono, etc)",
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
            "vaccines": "Esquema completo de vacunas según animal/edad y frecuencia de aplicación",
            "pregnancy": {
              "isPregnant": true/false,
              "weeks": "semanas",
              "days": "días",
              "months": "meses",
              "offspringCount": "número de crías estimado",
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
          - Si 'isSane' es true, omite 'healthStatus' y 'treatment', pero en el JSON final incluye 'treatment' con campos vacíos (no nulos) para evitar errores.
          - Si es positivo en embarazo, detalla semanas, días, meses y crías basándote en la captura.
        """),
        ...photos.map((bytes) => InlineDataPart('image/jpeg', bytes)),
      ];

      final response = await model.generateContent([Content.multi(promptParts)]);
      final data = jsonDecode(response.text!);

      // Construimos el bloque de texto para el historial combinando los campos
      // MANTENIENDO TU ESTRUCTURA ORIGINAL DE REPORTE
      String report = "";
      if (data['isSane']) {
        report = "ESTADO: SANO\n\nVACUNAS RECOMENDADAS:\n${data['vaccines']}";
      } else {
        // CORRECCIÓN PARA EVITAR ERROR NULL: Se añade verificación de existencia de campos
        final h = data['healthStatus'] ?? {};
        final t = data['treatment'] ?? {};
        
        report = "ENFERMEDAD: ${h['conditionName'] ?? 'No detectada'}\n"
                 "CAUSA: ${h['cause'] ?? 'N/A'}\n"
                 "GRAVEDAD: ${h['severity'] ?? 'Baja'}\n\n"
                 "TRATAMIENTO:\n"
                 "- Medicamento: ${t['medicineName'] ?? 'N/A'}\n"
                 "- Vía: ${t['type'] ?? 'N/A'}\n"
                 "- Dosis: ${t['dosage'] ?? 'N/A'}\n"
                 "- Frecuencia: ${t['frequency'] ?? 'N/A'}\n"
                 "- Duración: ${t['duration'] ?? 'N/A'}\n"
                 "- Aplicación: ${t['applicationSite'] ?? 'N/A'}\n"
                 "- Cuidados: ${t['careTips'] ?? 'N/A'}";
      }

      // Añadimos información de embarazo si es detectado (Solo si es positivo)
      if (data['pregnancy'] != null && data['pregnancy']['isPregnant'] == true) {
        report += "\n\nDETALLES DE GESTACIÓN:\n"
                  "- Estado: POSITIVO\n"
                  "- Tiempo: ${data['pregnancy']['weeks']} sem, ${data['pregnancy']['days']} días, ${data['pregnancy']['months']} meses\n"
                  "- Crías Estimadas: ${data['pregnancy']['offspringCount']}\n"
                  "- Duración Total: ${data['pregnancy']['totalDuration']}\n"
                  "- Días para el parto: ${data['pregnancy']['daysUntilDelivery']} días";
      }

      return ScanResult(
        id: "scan_${DateTime.now().millisecondsSinceEpoch}",
        animalType: data['animalType'] ?? animalCategory,
        breed: data['breed'],
        healthStatus: report,
        // CORRECCIÓN: PREVENTION TIPS
        preventionTips: data['isSane'] ? [data['vaccines'].toString()] : [data['treatment']['careTips']?.toString() ?? 'Sin notas'],
        isHighRisk: data['isSane'] ? false : (data['healthStatus']['isHighRisk'] ?? false),
        isPregnant: data['pregnancy']['isPregnant'] ?? false,
        offspringCount: data['pregnancy']['offspringCount']?.toString(),
        gestationWeeks: "${data['pregnancy']['weeks']} sem / ${data['pregnancy']['days']} d",
        daysUntilDelivery: data['pregnancy']['daysUntilDelivery'] ?? 0,
        totalGestationDuration: data['pregnancy']['totalDuration'],
        suggestedFoodName: data['nutrition']['foodName'] ?? '',
        foodRecommendation: data['nutrition']['recommendation'],
        rescanInterval: 3, 
        medicationDosage: data['isSane'] ? null : data['treatment']['dosage'],
        medicationRoute: data['isSane'] ? null : data['treatment']['type'],
        applicationSite: data['isSane'] ? null : data['treatment']['applicationSite'],
        photos: photos,
        timestamp: DateTime.now(),
        microchipId: microchipId,
      );
    } catch (e) {
      rethrow;
    }
  }
}