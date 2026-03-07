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
      // Usamos gemini-1.5-flash ya que gemini-2.0-flash a veces requiere configuraciones beta
      // o versiones de SDK muy específicas que pueden romper el build.
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash', 
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, 
        ),
      );

      final prompt = """
      ACTÚA COMO: Especialista en Medicina Veterinaria, Obstetricia y Seguimiento Clínico.

      TAREAS DE SEGUIMIENTO INTELIGENTE:
      1. GESTACIÓN: 
         - Si está embarazada, calcula 'days_until_delivery'.
         - Estima 'offspringCount' y 'delivery_alert_date'.
      2. PROTOCOLOS: Genera 3 cuidados preventivos obligatorios.
      3. CRONOGRAMA DE NOTIFICACIONES:
         - 'medication_days': [días para medicinas].
         - 'rescan_interval_days': 3.

      ESQUEMA JSON OBLIGATORIO:
      {
        "is_animal": true,
        "health_status_text": "...",
        "isPregnant": true,
        "gestationWeeks": "...",
        "offspringCount": "...",
        "days_until_delivery": 15,
        "delivery_forecast_text": "...",
        "prevention_tips": ["...", "..."],
        "medication_days": [1, 3, 7],
        "rescan_interval_days": 3,
        "observations": "..."
      }
      """;

      // SOLUCIÓN AL ERROR DE COMPILACIÓN:
      // Cambiamos InlineDataPart por DataPart (nombre oficial en el SDK de Firebase Vertex AI)
      final List<Content> content = [
        Content.multi([
          TextPart(prompt), 
          ...photos.map((bytes) => DataPart('image/jpeg', bytes))
        ])
      ];

      final response = await model.generateContent(content);
      
      if (response.text == null) throw Exception("La IA no devolvió respuesta");
      
      final Map<String, dynamic> aiJson = jsonDecode(response.text!.trim());
      final now = DateTime.now();

      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        animalId: animalId,
        healthStatus: aiJson['health_status_text'] ?? 'Sin diagnóstico',
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks']?.toString(),
        offspringCount: aiJson['offspringCount']?.toString(), // Aseguramos que sea String
        deliveryForecast: aiJson['delivery_forecast_text'],
        daysUntilDelivery: aiJson['days_until_delivery'] is int 
            ? aiJson['days_until_delivery'] 
            : int.tryParse(aiJson['days_until_delivery']?.toString() ?? ''),
        preventionTips: List<String>.from(aiJson['prevention_tips'] ?? []),
        medicationDays: List<int>.from(aiJson['medication_days'] ?? []),
        rescanInterval: aiJson['rescan_interval_days'] ?? 3,
        observations: aiJson['observations'],
      );
    } catch (e) { 
      print("Error en Diagnóstico IA: $e");
      rethrow; 
    }
  }
} 