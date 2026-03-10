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
      // CORRECCIÓN: Nombre de la instancia corregido a FirebaseVertexAI
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.5-flash-lite', 
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      // CORRECCIÓN: Declaramos la lista como List<Part> para evitar el error de List<dynamic>
      final List<Part> promptParts = [
        TextPart("""
          Actúa como un experto veterinario de élite. Analiza las imágenes de este $animalCategory.
          ID Microchip NFC: ${microchipId ?? 'No detectado'}. 
          Modo: $mode. 
          Seguimiento Evolutivo activo: ${isFollowUp ? 'SÍ' : 'NO'}.

          INSTRUCCIONES CRÍTICAS DE ALTA PRIORIDAD:
          1. DETECCIÓN DE RIESGO: Si detectas TUMORES, CÁNCER, o ENFERMEDADES DE ALTO RIESGO que requieran cirugía o atención inmediata, DEBES activar el campo "isHighRisk": true.
          2. ALERTA EMERGENTE: Si "isHighRisk" es true, el campo "healthStatus" DEBE comenzar con: "🚨 ALERTA DE ALTO RIESGO: SE REQUIERE ATENCIÓN VETERINARIA INMEDIATA 🚨".
          3. DETALLE DE ENFERMEDAD: Identifica el nombre de la enfermedad y su CAUSA exacta.
          
          TRATAMIENTO Y MEDICACIÓN (Campo 'treatmentPlan'):
          - MEDICINA: Nombre (pomada, inyección, gotas, pastilla).
          - DOSIS: ml exactos, número de pastillas, o número de gotas.
          - FRECUENCIA: Cada cuántas horas (Hrs).
          - DURACIÓN: Días totales de tratamiento.
          - APLICACIÓN: Lugar del cuerpo y método (inyectar, untar, oral).
          
          SI EL ANIMAL ESTÁ SANO:
          - En 'treatmentPlan', detalla el CALENDARIO DE VACUNACIÓN completo y preventivo según especie/raza.

          4. GESTACIÓN: Detalla crías, tiempo actual, duración total y días para el parto si aplica.
          5. CONTROL: Setea 'rescanInterval' en 3.

          Responde ÚNICAMENTE en este formato JSON:
          {
            "isHighRisk": true/false,
            "animalType": "Especie",
            "breed": "Raza detectada",
            "healthStatus": "Nombre Enfermedad + Causa + Diagnóstico",
            "treatmentPlan": "Detalle completo de Medicina, Dosis (ml/pastillas/gotas), Frecuencia, Duración y Lugar",
            "preventionTips": ["tip 1"],
            "isPregnant": true/false,
            "offspringCount": "número",
            "gestationWeeks": "semanas",
            "totalGestationDuration": "duración",
            "daysUntilDelivery": 10,
            "rescanInterval": 3,
            "suggestedFoodName": "Alimento",
            "foodRecommendation": "Guía nutricional"
          }
        """),
        // CORRECCIÓN: Integramos los DataPart directamente en la lista tipada
        ...photos.map((bytes) => DataPart('image/jpeg', bytes)),
      ];

      final response = await model.generateContent([Content.multi(promptParts)]);

      if (response.text == null) throw Exception("La IA no devolvió respuesta.");

      final data = jsonDecode(response.text!);

      return ScanResult(
        id: "scan_${DateTime.now().millisecondsSinceEpoch}",
        animalType: data['animalType'] ?? animalCategory,
        breed: data['breed'],
        healthStatus: "${data['healthStatus']}\n\n📋 PLAN MÉDICO / VACUNAS:\n${data['treatmentPlan']}",
        preventionTips: List<String>.from(data['preventionTips'] ?? []),
        isHighRisk: data['isHighRisk'] ?? false, 
        isPregnant: data['isPregnant'] ?? false,
        offspringCount: data['offspringCount'],
        gestationWeeks: data['gestationWeeks'],
        totalGestationDuration: data['totalGestationDuration'],
        daysUntilDelivery: data['daysUntilDelivery'],
        rescanInterval: data['rescanInterval'] ?? 3,
        suggestedFoodName: data['suggestedFoodName'] ?? '',
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