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
      // 1. Inicializamos el modelo de Vertex AI. 
      // No necesitamos API Key aquí porque Firebase usa la configuración de tu google-services.json
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1,
        ),
      );

      // 2. Preparamos el contenido (Texto + Imagen)
      final prompt = "Analiza la salud de este $animalCategory. "
          "Responde estrictamente en formato JSON con los campos: "
          "healthStatus (bueno/regular/critico), detectedBreed, diseaseName, "
          "medicationName, medicationDose, foodRecommendation, observations.";
      
      final imagePart = DataPart('image/jpeg', photos.first);

      // 3. Generamos el contenido
      final response = await model.generateContent([
        Content.multi([TextPart(prompt), imagePart])
      ]);

      final String? rawText = response.text;
      if (rawText == null) throw 'La IA no devolvió ninguna respuesta.';

      // Limpiamos el texto por si incluye decoradores de markdown
      final cleanJson = rawText.trim().replaceAll('```json', '').replaceAll('```', '');
      final Map<String, dynamic> aiJson = jsonDecode(cleanJson);
      
      final now = DateTime.now();

      // 4. Retornamos el resultado mapeado a tu modelo ScanResult
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
      // Si hay un error de "Permission Denied", es porque falta habilitar la API en la consola
      print('🚨 ERROR EN VERTEX AI: $e');
      rethrow;
    }
  }
}
