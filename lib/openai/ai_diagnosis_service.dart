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
        model: 'gemini-2.0-flash-lite', // Se recomienda usar gemini-2.0-flash-lite o pro para visión
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      final List<Part> promptParts = [
        TextPart("""
          INSTRUCCIÓN CRÍTICA DE VALIDACIÓN:
          1. Analiza si la imagen contiene un animal (perro, gato, vaca, caballo, etc.). 
          2. Si la imagen es de una persona, un objeto inanimado o un paisaje sin animales, DEBES responder ÚNICAMENTE con este JSON: 
             {"error": "error no es un animal"}

          INSTRUCCIONES DE DIAGNÓSTICO (Solo si hay un animal):
          Actúa como un experto veterinario de élite. Analiza las imágenes buscando:
          - Signos externos (piel, ojos, heridas).
          - Signos internos e indicadores fisiológicos: Analiza posturas, inflamaciones o síntomas visibles que sugieran problemas en la GARGANTA (obstrucciones, tos), ESTÓMAGO (torsión, hinchazón, indigestión), CEREBRO (problemas neurológicos, desorientación) y otros órganos.
          - Seguimiento Evolutivo activo: ${isFollowUp ? 'SÍ' : 'NO'}.

          DEBES RESPONDER ÚNICAMENTE EN JSON CON ESTA ESTRUCTURA EXACTA:

          {
            "animalType": "Especie detectada",
            "breed": "Raza",
            "isSane": true/false,
            "healthStatus": {
              "conditionName": "Nombre de la enfermedad (Externa o Interna como Gastritis, Obstrucción de garganta, etc) o 'SANO'",
              "cause": "Causa exacta",
              "severity": "ALTA, MEDIA o BAJA",
              "isHighRisk": true/false
            },
            "treatment": {
              "medicineName": "Nombre del fármaco",
              "type": "Oral, Inyección, etc",
              "dosage": "Cantidad exacta",
              "frequency": "Frecuencia",
              "duration": "Días",
              "applicationSite": "Lugar de aplicación",
              "careTips": "Cuidados preventivos"
            },
            "vaccines": "Esquema completo según especie",
            "pregnancy": {
              "isPregnant": true/false,
              "weeks": "semanas",
              "days": "días",
              "months": "meses",
              "offspringCount": "número de crías",
              "totalDuration": "duración total especie",
              "daysUntilDelivery": 10
            },
            "nutrition": {
              "foodName": "Alimento sugerido",
              "recommendation": "Guía nutricional"
            }
          }

          REGLAS:
          - No ignores el diagnóstico de órganos internos si las señales visuales lo sugieren.
          - Mantén la información de embarazo si es detectado tal cual se pidió.
        """),
        ...photos.map((bytes) => InlineDataPart('image/jpeg', bytes)),
      ];

      final response = await model.generateContent([Content.multi(promptParts)]);
      final data = jsonDecode(response.text!);

      // VALIDACIÓN DE ERROR: Si la IA detecta que no es un animal
      if (data.containsKey('error')) {
        throw Exception("error no es un animal");
      }

      String report = "";
      if (data['isSane']) {
        report = "ESTADO: SANO\n\nVACUNAS RECOMENDADAS:\n${data['vaccines']}";
      } else {
        final h = data['healthStatus'] ?? {};
        final t = data['treatment'] ?? {};

        report = "ENFERMEDAD/SÍNTOMA: ${h['conditionName'] ?? 'No detectada'}\n"
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
      // Si el error es el mensaje personalizado, lo relanzamos para capturarlo en la UI
      rethrow;
    }
  }
}