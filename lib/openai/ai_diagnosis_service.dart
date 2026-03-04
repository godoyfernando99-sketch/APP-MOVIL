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
    String? microchipId, // Cambiado de microchipNumber para coincidir con el llamado de la UI
    required List<Uint8List> photos,
  }) async {
    try {
      // Usamos Gemini 2.0 Flash optimizado para visión y medicina
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Un poco de flexibilidad para descriptores técnicos
          topP: 0.95,
        ),
      );

      // El microchipId se incluye en el contexto si existe
      final String idContext = (microchipId != null) 
          ? "IDENTIFICADOR DETECTADO POR NFC: $microchipId. Úsalo como ID oficial." 
          : "Sin identificador electrónico detectado.";

      // --- PROMPT DE NIVEL EXPERTO ---
      final prompt = """
      ACTÚA COMO: Un sistema de visión artificial veterinario de alta precisión.
      CONTEXTO DE IDENTIDAD: $idContext
      OBJETIVO: Diagnosticar la categoría: $animalCategory basada en las imágenes proporcionadas.

      INSTRUCCIONES CRÍTICAS:
      1. ANÁLISIS DE GESTACIÓN:
         - Evaluar distensión abdominal, estado de la glándula mamaria y postura.
         - Reportar tiempo estimado: Meses para grandes especies, Semanas para mascotas.

      2. EXAMEN FÍSICO VISUAL:
         - Detectar anomalías cutáneas, inflamación articular o desnutrición.
         - Identificar la raza con la mayor precisión posible.

      3. RECOMENDACIÓN FARMACOLÓGICA:
         - Si hay una patología evidente, sugiere Principio Activo + Nombre Comercial.
         - DOSIS: Obligatorio en formato "X ml por cada X kg".
         - VÍA DE ADMINISTRACIÓN: IM, SC, u Oral.

      REGLAS DE SEGURIDAD:
      - Si las imágenes no muestran un animal real, responde {"is_animal": false}.

      ESQUEMA DE RESPUESTA JSON:
      {
        "is_animal": true,
        "healthStatus": "crítico | regular | bueno",
        "detectedBreed": "Raza específica",
        "isPregnant": true,
        "gestationWeeks": "X semanas/meses (estimado)",
        "diseaseName": "Nombre técnico o 'Sano'",
        "medicationName": "Medicamento (Vía)",
        "medicationDose": "Fórmula de dosificación",
        "foodRecommendation": "Dieta específica",
        "observations": "Análisis técnico breve."
      }
      """;
      
      final List<Content> content = [
        Content.multi([
          TextPart(prompt),
          ...photos.map((bytes) => InlineDataPart('image/jpeg', bytes))
        ])
      ];

      final response = await model.generateContent(content);
      final String? rawText = response.text;
      
      if (rawText == null) throw 'Error: La IA no devolvió datos.';

      // Limpieza y parseo
      final cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

      if (aiJson['is_animal'] == false) {
        throw 'No se detectó un animal claro en las fotos. Por favor, captura imágenes nítidas.';
      }
      
      final now = DateTime.now();

      // Construcción del objeto final para el historial y resultados
      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        ownerId: 'user_active',
        createdAt: now,
        updatedAt: now,
        animalId: animalId,
        animalCategory: animalCategory,
        mode: mode,
        microchipNumber: microchipId, // Se guarda el ID obtenido por NFC
        photosBase64: photos.map((p) => base64Encode(p)).toList(),
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: animalCategory,
        diseaseName: aiJson['diseaseName'] ?? 'No detectada',
        medicationName: aiJson['medicationName'] ?? 'N/A',
        medicationDose: aiJson['medicationDose'] ?? 'N/A',
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'] ?? 'N/A', 
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Dieta estándar',
        observations: aiJson['observations'] ?? 'Analizado con Vertex AI Pro-Vision.',
      );
    } catch (e) {
      print('🚨 ERROR EN SERVICIO IA: $e');
      rethrow;
    }
  }
}
