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
          temperature: 0.1,
        ),
      );

      // --- PROMPT MEJORADO CON FILTRO ---
      final prompt = """
      Eres un experto veterinario. Analiza la imagen y sigue estas reglas:
      1. Si la imagen NO contiene un animal real (es una persona, un objeto, un logo o algo no relacionado), responde ÚNICAMENTE: {"is_animal": false}
      2. Si hay un animal, analiza su salud y responde en este formato JSON:
      {
        "is_animal": true,
        "healthStatus": "bueno/regular/critico",
        "detectedBreed": "raza",
        "diseaseName": "enfermedad",
        "medicationName": "medicamento",
        "medicationDose": "dosis",
        "foodRecommendation": "comida",
        "observations": "observaciones"
      }
      """;
      
      final imagePart = InlineDataPart('image/jpeg', photos.first);

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), imagePart])
      ]);

      final String? rawText = response.text;
      if (rawText == null) throw 'La IA no devolvió ninguna respuesta.';

      final cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      final Map<String, dynamic> aiJson = jsonDecode(cleanJson);

      // --- VALIDACIÓN DE ANIMAL ---
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
        photosBase64: [base64Encode(photos.first)],
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['detectedBreed'] ?? 'Desconocida',
        detectedSpecies: animalCategory,
        diseaseName: aiJson['diseaseName'] ?? 'No detectada',
        medicationName: aiJson['medicationName'] ?? 'N/A',
        medicationDose: aiJson['medicationDose'] ?? 'N/A',
        isPregnant: false,
        foodRecommendation: aiJson['foodRecommendation'] ?? 'Consultar veterinario',
        observations: aiJson['observations'] ?? 'Análisis realizado con Vertex AI.',
      );
    } catch (e) {
      print('🚨 ERROR EN VERTEX AI: $e');
      rethrow; // Este mensaje llegará al SnackBar de tu pantalla de captura
    }
  }
}
