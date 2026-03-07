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

      final prompt = """
      ACTÚA COMO: Especialista en Cirugía Veterinaria, Oncología y Medicina de Emergencias.

      REGLAS DE SEGURIDAD:
      - Si la imagen muestra humanos, comida u objetos inanimados, establece 'is_animal': false.

      REGLAS DE DIAGNÓSTICO (Si 'is_animal': true):
      1. TRIAGE Y CIRUGÍA: Si detectas Tumores, Fracturas, Heridas profundas, Desnutrición extrema o Parásitos críticos:
         - El campo 'health_status_text' DEBE SER EXACTAMENTE: "🚨 ALERTA: URGENTE OPERAR / LLEVAR AL VETERINARIO".
      2. DOLOR: Estima Nivel de Dolor (Bajo, Moderado, Alto).
      3. GESTACIÓN: Indica tiempo estimado en DÍAS, SEMANAS o MESES.
      4. TRATAMIENTO Y COLOCACIÓN: 
         - 'medicationDose' DEBE detallar la dosis Y EL LUGAR/FORMA DE COLOCACIÓN (ej: "5ml - Inyectable Intramuscular en la tabla del cuello", "Pomada tópica en zona afectada").
      5. ALIMENTO: Formato NOMBRE PRODUCTO EN MAYÚSCULAS: Explicación detallada.

      ESQUEMA JSON OBLIGATORIO:
      {
        "is_animal": true,
        "species": "Especie detectada",
        "breed": "Raza detectada",
        "health_status_text": "🚨 ALERTA: URGENTE OPERAR / LLEVAR AL VETERINARIO | bueno | regular",
        "pain_level": "Bajo | Moderado | Alto",
        "diseaseName": "Nombre patología o 'Sano'",
        "medicationName": "Medicamento",
        "medicationDose": "Dosis y guía de aplicación detallada",
        "isPregnant": true/false,
        "gestationWeeks": "Tiempo de preñez (ej: 45 días)",
        "foodRecommendation": "NOMBRE: Detalle",
        "observations": "Análisis clínico técnico."
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
        throw '⚠️ No se detectó un animal. Por favor, enfoca bien al ejemplar.';
      }

      final now = DateTime.now();

      return ScanResult(
        id: now.millisecondsSinceEpoch.toString(),
        ownerId: 'user_active',
        createdAt: now,
        updatedAt: now,
        animalId: animalId,
        animalCategory: animalCategory,
        mode: mode,
        microchipNumber: microchipId,
        photosBase64: photos.map((p) => base64Encode(p)).toList(),
        healthStatus: aiJson['health_status_text'] ?? 'regular',
        detectedBreed: aiJson['breed'] ?? 'No identificada',
        detectedSpecies: aiJson['species'] ?? animalCategory,
        diseaseName: aiJson['diseaseName'],
        medicationName: aiJson['medicationName'],
        medicationDose: aiJson['medicationDose'],
        isPregnant: aiJson['isPregnant'] ?? false,
        gestationWeeks: aiJson['gestationWeeks'],
        foodRecommendation: aiJson['foodRecommendation'],
        observations: "NIVEL DE DOLOR: ${aiJson['pain_level']}. ${aiJson['observations']}",
      );
    } catch (e) {
      print('🚨 ERROR IA SERVICE: $e');
      rethrow;
    }
  }
}