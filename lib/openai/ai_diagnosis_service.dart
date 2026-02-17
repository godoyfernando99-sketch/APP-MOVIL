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
          temperature: 0.1, // Precisión máxima
        ),
      );

      // --- PROMPT MEJORADO: ESPECIALISTA VETERINARIO Y FARMACOLOGÍA ---
      final prompt = """
      Eres un experto veterinario con especialidad en diagnóstico clínico, obstetricia y farmacología.
      Tu tarea es analizar la salud de un animal de la categoría: $animalCategory.

      REGLAS DE VALIDACIÓN:
      1. Si la imagen NO es un animal real o es ilegible, responde: {"is_animal": false}

      REGLAS DE ANÁLISIS MÉDICO:
      2. Si detectas una enfermedad (diseaseName), identifica obligatoriamente:
         - medicationName: Nombre genérico y comercial del medicamento adecuado.
         - Vía de administración: Especifica claramente si es ORAL o INYECTADO.
         - medicationDose: Si es inyectado, indica la dosis exacta en mililitros (ml) o centímetros cúbicos (cc) por cada kilogramo de peso del animal (ej. 1ml/10kg). Si es oral, indica mg/kg.
         - foodRecommendation: Nombre del alimento o dieta clínica específica según la patología y la especie.
      
      3. Evaluación de Preñez (Gestation):
         - Identifica desarrollo mamario o distensión abdominal.
         - gestationWeeks: Indica el tiempo en días o semanas según la especie.

      Responde estrictamente en este formato JSON:
      {
        "is_animal": true,
        "healthStatus": "bueno/regular/critico",
        "detectedBreed": "raza detectada",
        "isPregnant": true/false,
        "gestationWeeks": "X semanas/días o N/A",
        "diseaseName": "nombre de la enfermedad o 'No detectada'",
        "medicationName": "nombre del medicamento + vía (ej. Enrofloxacina - Inyectable)",
        "medicationDose": "Dosis referencial (ej. 0.5ml por cada 10kg)",
        "foodRecommendation": "dieta específica sugerida",
        "observations": "Resumen médico incluyendo advertencia de pesar al animal antes de medicar."
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
        photosBase64: photos.map((p) => base64Encode(p)).toList(),
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: animalCategory,
        diseaseName: aiJson['diseaseName'] ?? 'No detectada',
        medicationName: aiJson['medicationName'] ?? 'N/A',
        medicationDose: aiJson['medicationDose'] ?? 'N/A',
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'] ?? 'N/A', 
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Consultar dieta con especialista',
        observations: aiJson['observations'] ?? 'Análisis realizado con Vertex AI.',
      );
    } catch (e) {
      print('🚨 ERROR EN VERTEX AI: $e');
      rethrow;
    }
  }
}
