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
          topP: 0.95,
        ),
      );

      final String idContext = (microchipId != null) 
          ? "IDENTIFICADOR DETECTADO POR NFC: $microchipId." 
          : "Sin identificador electrónico.";

      // --- PROMPT OPTIMIZADO PARA LOS NUEVOS CAMPOS ---
      final prompt = """
      ACTÚA COMO: Especialista en Medicina Veterinaria y Nutrición Animal.
      CONTEXTO: $idContext
      CATEGORÍA SELECCIONADA: $animalCategory.

      TAREAS CRÍTICAS:
      1. IDENTIFICACIÓN: Determina la especie exacta (Ej: Perro, Gato, Vaca, Caballo) y su raza.
      2. NUTRICIÓN (CLAVE): Sugiere un alimento específico. 
         - Debes escribir el nombre del producto en MAYÚSCULAS seguido de dos puntos y luego la explicación.
         - Ejemplo: "ROYAL CANIN PUPPY: Alimento diseñado para el crecimiento óseo..."
      3. SALUD: Detecta signos de enfermedad, parásitos o lesiones.
      4. GESTACIÓN: Si es hembra, evalúa signos de preñez y estima semanas.

      ESQUEMA DE RESPUESTA JSON OBLIGATORIO:
      {
        "is_animal": true,
        "species": "Especie detectada (ej: Perro)",
        "breed": "Raza detectada",
        "healthStatus": "bueno | regular | crítico",
        "diseaseName": "Nombre de patología o 'Sano'",
        "medicationName": "Medicamento y vía",
        "medicationDose": "Dosis exacta (ej: 1ml/10kg)",
        "isPregnant": false,
        "gestationWeeks": "N/A",
        "foodRecommendation": "NOMBRE DEL ALIMENTO: Explicación detallada de por qué este alimento.",
        "observations": "Análisis clínico breve."
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

      if (rawText == null) throw 'Error de comunicación con IA.';

      final Map<String, dynamic> aiJson = jsonDecode(rawText.trim());

      if (aiJson['is_animal'] == false) {
        throw 'No se detectó un animal en las imágenes.';
      }

      final now = DateTime.now();

      // Construcción con mapeo a los campos de ScanResult
      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        ownerId: 'user_active',
        createdAt: now,
        updatedAt: now,
        animalId: animalId,
        animalCategory: animalCategory, // Categoría del catálogo
        mode: mode,
        microchipNumber: microchipId,
        photosBase64: photos.map((p) => base64Encode(p)).toList(),
        healthStatus: aiJson['healthStatus'] ?? 'regular',
        detectedBreed: aiJson['breed'] ?? 'No identificada',
        detectedSpecies: aiJson['species'] ?? animalCategory, // IA corrige la especie
        diseaseName: aiJson['diseaseName'],
        medicationName: aiJson['medicationName'],
        medicationDose: aiJson['medicationDose'],
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'], 
        foodRecommendation: aiJson['foodRecommendation'], // Aquí viene el formato NOMBRE: INFO
        observations: aiJson['observations'],
      );
    } catch (e) {
      print('🚨 ERROR IA SERVICE: $e');
      rethrow;
    }
  }
}