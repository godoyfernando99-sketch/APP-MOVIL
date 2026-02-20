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
      // Usamos Gemini 2.0 Flash que es excelente siguiendo instrucciones complejas
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.0, // Bajamos a 0.0 para eliminar cualquier alucinación creativa
          topP: 0.95,
        ),
      );

      // --- PROMPT DE NIVEL EXPERTO (VETERINARY ONCOLOGY & OBSTETRICS) ---
      final prompt = """
      ACTÚA COMO: Un sistema de visión artificial veterinario de alta precisión especializado en grandes y pequeñas especies.
      OBJETIVO: Diagnosticar la categoría: $animalCategory basada en imágenes.

      INSTRUCCIONES CRÍTICAS DE ANÁLISIS:
      1. ANÁLISIS DE GESTACIÓN (OBSTETRICIA):
         - Observa la distensión del flanco derecho, descenso de la ubre y edema pre-parto.
         - Si detectas gestación, estima el tiempo basándote en la morfología externa:
           * Bovinos: Indica meses (ej. "7 meses / 210 días").
           * Caninos/Felinos: Indica semanas (ej. "6 semanas / 42 días").
         - Sé específico: "Gestación temprana", "Gestación a término" o "No gestante".

      2. TRAUMATOLOGÍA Y LESIONES:
         - Analiza la angulación de las patas (desviaciones óseas), inflamación de articulaciones (nudos, corvejones) y heridas abiertas.
         - Clasifica fracturas visibles o cojeras evidentes por postura.

      3. FARMACOLOGÍA Y DOSIS (ESTRICTO):
         - Si hay enfermedad, indica el principio activo Y un nombre comercial común.
         - FORMATO DE DOSIS: Debe ser una fórmula aplicable. Ej: "1 ml por cada 20 kg de peso vivo".
         - VÍA: Especificar IM (Intramuscular), SC (Subcutánea) u Oral.

      REGLAS DE SEGURIDAD:
      - Si la imagen NO es un animal real o no hay suficiente claridad para un diagnóstico médico, responde {"is_animal": false}.

      ESQUEMA DE RESPUESTA JSON (Sigue este formato exacto):
      {
        "is_animal": true,
        "healthStatus": "crítico | regular | bueno",
        "detectedBreed": "Raza específica",
        "isPregnant": true,
        "gestationWeeks": "X semanas/meses (estimado preciso)",
        "diseaseName": "Nombre técnico de la patología o 'Sano'",
        "medicationName": "Principio Activo + Nombre Comercial (Vía)",
        "medicationDose": "X ml por cada X kg",
        "foodRecommendation": "Dieta terapéutica recomendada",
        "observations": "Resumen técnico. Advertir que el peso exacto es obligatorio antes de inyectar."
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
      
      if (rawText == null) throw 'Error: El motor de IA no generó datos.';

      // Limpieza de formato Markdown
      final cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

      if (aiJson['is_animal'] == false) {
        throw 'La imagen no es lo suficientemente clara o no es un animal. Por favor, intenta de nuevo.';
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
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Dieta estándar',
        observations: aiJson['observations'] ?? 'Analizado con Vertex AI Pro-Vision.',
      );
    } catch (e) {
      print('🚨 ERROR CRÍTICO IA: $e');
      rethrow;
    }
  }
}
