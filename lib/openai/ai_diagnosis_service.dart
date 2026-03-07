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
        ),
      );

      final prompt = """
      ACTÚA COMO: Especialista en Medicina Veterinaria, Obstetricia y Seguimiento Clínico.

      TAREAS DE SEGUIMIENTO INTELIGENTE:
      1. GESTACIÓN: 
         - Si está embarazada, calcula 'days_until_delivery' (número de días faltantes).
         - Estima 'offspringCount' y 'delivery_alert_date' (fecha sugerida para alerta de parto).
      2. PROTOCOLOS: Genera 3 cuidados preventivos obligatorios.
      3. CRONOGRAMA DE NOTIFICACIONES:
         - Genera 'medication_reminders': [días para medicinas].
         - Genera 'rescan_reminder': true (siempre true para seguimiento cada 3 días).
         - Genera 'protocol_check_days': [días para preguntar si cumplió los cuidados].

      ESQUEMA JSON:
      {
        "is_animal": true,
        "health_status_text": "...",
        "isPregnant": true/false,
        "gestationWeeks": "...",
        "offspringCount": "...",
        "days_until_delivery": 15,
        "delivery_forecast_text": "Faltan aprox. 15 días para el parto",
        "prevention_tips": ["...", "..."],
        "medication_days": [1, 3, 7],
        "rescan_interval_days": 3,
        "observations": "..."
      }
      """;

      final List<Content> content = [
        Content.multi([TextPart(prompt), ...photos.map((b) => InlineDataPart('image/jpeg', b))])
      ];

      final response = await model.generateContent(content);
      final Map<String, dynamic> aiJson = jsonDecode(response.text!.trim());

      final now = DateTime.now();

      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        animalId: animalId,
        healthStatus: aiJson['health_status_text'],
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'],
        offspringCount: aiJson['offspringCount'],
        deliveryForecast: aiJson['delivery_forecast_text'],
        daysUntilDelivery: aiJson['days_until_delivery'],
        preventionTips: List<String>.from(aiJson['prevention_tips'] ?? []),
        // Estos campos activarán las notificaciones en la UI
        medicationDays: List<int>.from(aiJson['medication_days'] ?? []),
        rescanInterval: aiJson['rescan_interval_days'] ?? 3,
        observations: aiJson['observations'],
      );
    } catch (e) { rethrow; }
  }
}