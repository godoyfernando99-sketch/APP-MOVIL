import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:scanneranimal/app/history/scan_models.dart';

class AiDiagnosisService {
  const AiDiagnosisService();

  Future<ScanResult> diagnose({
    required String animalId,
    required String animalCategory,
    required String mode,
    String? microchipId, 
    required List<Uint8List> photos,
  }) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, 
          topP: 0.95,
        ),
      );

      final prompt = """
      ACTÚA COMO: Especialista en Reproducción Animal, Ecografía y Medicina Preventiva.

      REGLAS CRÍTICAS:
      1. GESTACIÓN PRO: Si detectas embarazo:
         - 'gestationWeeks': Indica tiempo transcurrido (días/semanas/meses).
         - 'offspringCount': Estima el número de crías (ej: "3-4 crías" o "1 cría").
         - 'totalGestationPeriod': Indica cuánto dura el embarazo en esta especie (ej: "63 días", "9 meses").
         - 'deliveryForecast': Calcula cuánto falta para el parto.

      2. ALERTAS DE EMERGENCIA: Si hay tumores, fracturas o desnutrición severa, inicia 'health_status_text' con "🚨 ALERTA: URGENTE OPERAR / VETERINARIO".

      3. PREVENCIÓN: Además del tratamiento, indica 'prevention_tips': 3 pasos para evitar que esta enfermedad regrese.

      4. RECORDATORIOS: Lista de días [1, 7, 30] para notificaciones de tratamiento.

      ESQUEMA JSON OBLIGATORIO:
      {
        "is_animal": true,
        "species": "Especie",
        "breed": "Raza",
        "health_status_text": "Estado o Alerta URGENTE",
        "diseaseName": "Patología",
        "medicationDose": "Dosis y guía de aplicación",
        "isPregnant": true/false,
        "gestationWeeks": "Tiempo actual",
        "offspringCount": "Número de crías estimado",
        "totalGestationPeriod": "Duración total especie",
        "deliveryForecast": "Tiempo restante para parto",
        "prevention_tips": ["Paso 1", "Paso 2"],
        "reminder_days": [1, 7, 14],
        "care_instructions": ["Cuidado post-tratamiento"],
        "observations": "Análisis clínico."
      }
      """;

      final List<Content> content = [
        Content.multi([TextPart(prompt), ...photos.map((b) => InlineDataPart('image/jpeg', b))])
      ];

      final response = await model.generateContent(content);
      final Map<String, dynamic> aiJson = jsonDecode(response.text!.trim());

      if (aiJson['is_animal'] == false) throw 'No se detectó un animal.';

      final now = DateTime.now();

      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        animalId: animalId,
        healthStatus: aiJson['health_status_text'],
        detectedBreed: aiJson['breed'],
        detectedSpecies: aiJson['species'],
        diseaseName: aiJson['diseaseName'],
        medicationDose: aiJson['medicationDose'],
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'],
        // Campos nuevos para reproducción y prevención
        offspringCount: aiJson['offspringCount'],
        totalGestationPeriod: aiJson['totalGestationPeriod'],
        deliveryForecast: aiJson['deliveryForecast'],
        preventionTips: List<String>.from(aiJson['prevention_tips'] ?? []),
        reminderDays: List<int>.from(aiJson['reminder_days'] ?? []),
        careInstructions: List<String>.from(aiJson['care_instructions'] ?? []),
        observations: aiJson['observations'],
      );
    } catch (e) {
      rethrow;
    }
  }
}