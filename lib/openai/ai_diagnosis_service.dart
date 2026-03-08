import 'dart:typed_data';
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
    // Simulamos un retraso de procesamiento de IA
    await Future.delayed(const Duration(seconds: 3));
    final now = DateTime.now();

    try {
      // Aquí iría tu lógica real con Vertex AI / OpenAI
      // Por ahora, construimos el resultado con los parámetros corregidos
      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(), // AHORA SÍ RECONOCE EL ID
        animalType: animalCategory,
        healthStatus: "Estado Saludable",
        preventionTips: [
          "Mantener hidratación constante",
          "Observar comportamiento en las próximas 24h",
          "Programar revisión de rutina"
        ],
        isPregnant: mode == 'gestation',
        offspringCount: mode == 'gestation' ? "4-5 estimadas" : null,
        gestationWeeks: mode == 'gestation' ? "5 semanas" : null,
        daysUntilDelivery: mode == 'gestation' ? 20 : null,
        rescanInterval: 5,
        medicationDays: [1, 3, 7],
        foodRecommendation: "Alimento rico en proteínas y omega 3",
        suggestedFoodName: "Premium Vet Diet",
        photos: photos,
        microchipId: microchipId,
      );
    } catch (e) {
      debugPrint("Error en diagnóstico IA: $e");
      rethrow;
    }
  }
}