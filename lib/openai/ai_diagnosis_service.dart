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
    String? microchipNumber,
    required List<Uint8List> photos,
  }) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Baja temperatura para precisión diagnóstica
        ),
      );

      // --- PROMPT ULTRA MEJORADO: ESPECIALISTA EN GESTACIÓN ---
      final prompt = """
      Eres un experto veterinario especializado en diagnóstico por imagen y obstetricia.
      Tu tarea es analizar la salud de una hembra de la categoría: $animalCategory.

      REGLAS DE VALIDACIÓN:
      1. Si la imagen NO es un animal real, responde: {"is_animal": false}

      REGLAS DE ANÁLISIS:
      2. Evalúa signos de preñez/embarazo:
         - En animales de granja (vaca, cabra, oveja): Observa distensión abdominal lateral derecha y desarrollo de la ubre.
         - En mascotas (perra, gata): Observa crecimiento abdominal y cambios en las mamas.
      
      Responde estrictamente en este formato JSON:
      {
        "is_animal": true,
        "healthStatus": "bueno/regular/critico",
        "detectedBreed": "raza",
        "isPregnant": true/false,
        "gestationWeeks": "indicar semanas o días aproximados (especificando si son días o semanas) basado en el tamaño fetal visible y desarrollo mamario. Si no hay embarazo, poner N/A",
        "diseaseName": "enfermedad",
        "medicationName": "medicamento",
        "medicationDose": "dosis",
        "foodRecommendation": "comida",
        "observations": "Breve nota sobre el estado de gestación y salud general."
      }
      """;
      
      // CARGAMOS TODAS LAS FOTOS PARA UN ANÁLISIS COMPLETO (Varios ángulos)
      final List<Content> content = [
        Content.multi([
          TextPart(prompt),
          ...photos.map((bytes) => InlineDataPart('image/jpeg', bytes))
        ])
      ];

      final response = await model.generateContent(content);

      final String? rawText = response.text;
      if (rawText == null) throw 'La IA no devolvió ninguna respuesta.';

      final cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

      if (aiJson['is_animal'] == false) {
        throw 'Esa no es una imagen de un animal. Por favor, coloca la imagen del animal seleccionado.';
      }
      
      final now = DateTime.now();

      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        ownerId: 'user_test',
        createdAt: now,
        updatedAt: now,
        animalId: animalId,
        animalCategory: animalCategory,
        mode: mode,
        microchipNumber: microchipNumber,
        // Guardamos todas las fotos procesadas
        photosBase64: photos.map((p) => base64Encode(p)).toList(),
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: animalCategory,
        diseaseName: aiJson['diseaseName'] ?? 'No detectada',
        medicationName: aiJson['medicationName'] ?? 'N/A',
        medicationDose: aiJson['medicationDose'] ?? 'N/A',
        // NUEVOS DATOS DE GESTACIÓN
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'] ?? 'N/A', 
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Consultar veterinario',
        observations: aiJson['observations'] ?? 'Análisis realizado con Vertex AI.',
      );
    } catch (e) {
      print('🚨 ERROR EN VERTEX AI: $e');
      rethrow;
    }
  }
}
