import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/openai/openai_config.dart';

class AiDiagnosisService {
  const AiDiagnosisService();

  Future<ScanResult> diagnose({
    required String animalId,
    required String animalCategory,
    required String mode,
    String? microchipNumber,
    required List<Uint8List> photos,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      debugPrint('OpenAI not configured; returning mock diagnosis.');
      return _mock(animalId: animalId, animalCategory: animalCategory, mode: mode, microchipNumber: microchipNumber, photos: photos);
    }

    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text':
            'Eres un veterinario experto asistido por IA. Analiza CUIDADOSAMENTE las 3 fotografías del animal tomadas desde diferentes ángulos.\n\n'
            'Animal: $animalCategory (ID: $animalId)\n\n'
            'INSTRUCCIONES DETALLADAS:\n\n'
            '1. ESTADO DE SALUD (healthStatus):\n'
            '   - Evalúa condición física general, pelaje/plumaje, ojos, postura, respiración\n'
            '   - "buena": Animal saludable, activo, sin signos visibles de enfermedad\n'
            '   - "regular": Signos leves de malestar o condiciones menores\n'
            '   - "mala": Signos claros de enfermedad, lesiones o condición crítica\n\n'
            '2. ENFERMEDADES (diseaseName):\n'
            '   - Si detectas CUALQUIER signo de enfermedad, especifica el nombre exacto\n'
            '   - Busca: secreciones, hinchazón, erupciones, cambios de color, lesiones, parásitos visibles, comportamiento anormal\n'
            '   - Ejemplos: "Conjuntivitis", "Dermatitis", "Mastitis", "Neumonía", "Coccidiosis", "Sarna", etc.\n'
            '   - Si NO hay signos de enfermedad: null\n\n'
            '3. FRACTURAS (fractureDescription):\n'
            '   - Busca ESPECÍFICAMENTE: extremidades en ángulos anormales, hinchazón, deformidades óseas, cojera evidente\n'
            '   - Si detectas fractura, indica LA PARTE EXACTA: "pata delantera izquierda", "pata trasera derecha", "ala izquierda", "costilla", etc.\n'
            '   - Ejemplo: "Posible fractura en pata trasera derecha - hinchazón y ángulo anormal"\n'
            '   - Si NO hay signos de fractura: null\n\n'
            '4. EMBARAZO (isPregnant y pregnancyWeeks):\n'
            '   - Evalúa SOLO si es hembra y hay signos claros: abdomen distendido, glándulas mamarias desarrolladas, cambios posturales\n'
            '   - isPregnant: true SOLO si hay evidencia clara, false si claramente no está embarazada, null si no se puede determinar o es macho\n'
            '   - pregnancyWeeks: Estima semanas/días basándote en el tamaño abdominal y desarrollo mamario\n'
            '   - Para vacas: embarazo ~280 días (40 semanas)\n'
            '   - Para ovejas/cabras: ~150 días (21 semanas)\n'
            '   - Para cerdos: ~114 días (16 semanas)\n'
            '   - Para perros: ~63 días (9 semanas)\n'
            '   - Ejemplo: 12 (semanas), 35 (semanas), etc.\n\n'
            '5. MEDICACIÓN (medicationName y medicationDose):\n'
            '   - Recomienda tratamiento ESPECÍFICO basado en la condición detectada\n'
            '   - medicationName: nombre del medicamento o tipo de tratamiento\n'
            '   - medicationDose: guía general cualitativa, NO números exactos\n'
            '   - Ejemplo: "Antibiótico de amplio espectro" con dosis "Según peso del animal; consultar veterinario"\n\n'
            '6. ALIMENTACIÓN (foodRecommendation):\n'
            '   - Recomendaciones específicas según condición y tipo de animal\n\n'
            'FORMATO DE RESPUESTA (JSON exacto):\n'
            '{\n'
            '  "healthStatus": "buena"|"regular"|"mala",\n'
            '  "diseaseName": string|null,\n'
            '  "fractureDescription": string|null,\n'
            '  "medicationName": string|null,\n'
            '  "medicationDose": string|null,\n'
            '  "isPregnant": boolean|null,\n'
            '  "pregnancyWeeks": number|null,\n'
            '  "foodRecommendation": string|null\n'
            '}\n\n'
            'IMPORTANTE: Sé PRECISO y ESPECÍFICO. Si detectas algo, nómbralo claramente. Si no hay evidencia, usa null.',
      },
      for (final p in photos)
        {
          'type': 'image_url',
          'image_url': {'url': OpenAiConfig.dataUrlFromBytes(p)},
        },
    ];

    final body = {
      'model': 'gpt-4o',
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'Devuelve el resultado como un objeto JSON.',
        },
        {
          'role': 'user',
          'content': content,
        },
      ],
    };

    final res = await OpenAiConfig.postJson(body);
    final text = (((res['choices'] as List?)?.first as Map?)?['message'] as Map?)?['content']?.toString();
    if (text == null || text.isEmpty) throw Exception('Empty OpenAI content');

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) throw Exception('Not a JSON object');
      json = decoded;
    } catch (e) {
      debugPrint('Malformed JSON from OpenAI: $e');
      debugPrint('Raw: $text');
      throw Exception('Malformed AI JSON');
    }

    final photoB64 = photos.map((p) => base64Encode(p)).toList();
    final now = DateTime.now();
    return ScanResult(
      id: _id(),
      ownerId: '', // Will be set when saving to Firestore
      createdAt: now,
      updatedAt: now,
      animalId: animalId,
      animalCategory: animalCategory,
      mode: mode,
      microchipNumber: microchipNumber,
      photosBase64: photoB64,
      healthStatus: (json['healthStatus'] ?? 'regular').toString(),
      diseaseName: json['diseaseName']?.toString(),
      fractureDescription: json['fractureDescription']?.toString(),
      medicationName: json['medicationName']?.toString(),
      medicationDose: json['medicationDose']?.toString(),
      isPregnant: json['isPregnant'] is bool ? json['isPregnant'] as bool : null,
      pregnancyWeeks: json['pregnancyWeeks'] is num ? (json['pregnancyWeeks'] as num).toInt() : null,
      foodRecommendation: json['foodRecommendation']?.toString(),
    );
  }

  ScanResult _mock({
    required String animalId,
    required String animalCategory,
    required String mode,
    required String? microchipNumber,
    required List<Uint8List> photos,
  }) {
    final rnd = Random();
    final photoB64 = photos.map((p) => base64Encode(p)).toList();
    final now = DateTime.now();
    
    // Determinar estado de salud con distribución más realista
    final healthRoll = rnd.nextInt(100);
    final health = healthRoll < 60 ? 'buena' : (healthRoll < 85 ? 'regular' : 'mala');
    
    // Enfermedades comunes por categoría de animal
    final diseasesByCategory = {
      'Vacuno': ['Mastitis', 'Neumonía', 'Fiebre de leche', 'Pododermatitis', 'Brucelosis'],
      'Ovino': ['Neumonía enzoótica', 'Coccidiosis', 'Pedero', 'Ectima contagioso', 'Toxoplasmosis'],
      'Caprino': ['Neumonía', 'Mastitis', 'Parasitosis gastrointestinal', 'Artritis encefalitis caprina'],
      'Porcino': ['Neumonía enzoótica', 'Diarrea epidémica porcina', 'Erisipela porcina', 'Parvovirosis'],
      'Avícola': ['Newcastle', 'Bronquitis infecciosa', 'Coccidiosis', 'Coriza infecciosa', 'Viruela aviar'],
      'Equino': ['Cólico', 'Laminitis', 'Influenza equina', 'Dermatofitosis', 'Adenitis equina'],
      'Canino': ['Parvovirus', 'Moquillo', 'Otitis', 'Dermatitis alérgica', 'Gastroenteritis'],
    };
    
    // Partes del cuerpo para fracturas
    final fractureParts = [
      'pata delantera izquierda',
      'pata delantera derecha',
      'pata trasera izquierda',
      'pata trasera derecha',
      'costilla lateral izquierda',
      'ala izquierda',
      'ala derecha',
      'fémur derecho',
    ];
    
    // Decidir condiciones basadas en el estado de salud
    final hasDisease = health == 'mala' || (health == 'regular' && rnd.nextInt(10) < 6);
    final hasFracture = health == 'mala' ? rnd.nextInt(10) < 4 : rnd.nextInt(10) < 1;
    
    String? diseaseName;
    String? medicationName;
    String? medicationDose;
    if (hasDisease) {
      final diseases = diseasesByCategory[animalCategory] ?? ['Infección respiratoria', 'Parasitosis', 'Dermatitis'];
      diseaseName = diseases[rnd.nextInt(diseases.length)];
      
      // Medicación específica según enfermedad
      if (diseaseName.contains('Mastitis')) {
        medicationName = 'Antibiótico intramamario (Cefalosporinas)';
        medicationDose = 'Aplicar en cuartos afectados; consultar veterinario';
      } else if (diseaseName.contains('Neumonía') || diseaseName.contains('respiratoria')) {
        medicationName = 'Antibiótico de amplio espectro (Oxitetraciclina)';
        medicationDose = 'Según peso corporal; repetir cada 48-72h';
      } else if (diseaseName.contains('Diarrea') || diseaseName.contains('gastrointestinal') || diseaseName.contains('Coccidiosis')) {
        medicationName = 'Electrolitos orales + Anticoccidiano';
        medicationDose = 'Rehidratación constante; consultar veterinario';
      } else if (diseaseName.contains('Dermatitis') || diseaseName.contains('Sarna') || diseaseName.contains('Dermatofitosis')) {
        medicationName = 'Antimicótico tópico + Baños medicados';
        medicationDose = 'Aplicar 2 veces al día durante 14 días';
      } else {
        medicationName = 'Tratamiento específico según diagnóstico';
        medicationDose = 'Consultar veterinario para dosis exacta';
      }
    }
    
    String? fractureDescription;
    if (hasFracture) {
      final part = fractureParts[rnd.nextInt(fractureParts.length)];
      fractureDescription = 'Posible fractura en $part - se observa hinchazón y ángulo anormal';
    }
    
    // Embarazo: solo para hembras y con probabilidad realista
    bool? isPregnant;
    int? pregnancyWeeks;
    final femaleAnimals = ['Vacuno', 'Ovino', 'Caprino', 'Porcino', 'Equino'];
    if (femaleAnimals.contains(animalCategory) && rnd.nextInt(10) < 3) {
      isPregnant = true;
      // Semanas apropiadas según especie
      if (animalCategory == 'Vacuno') {
        pregnancyWeeks = 10 + rnd.nextInt(30); // 10-40 semanas
      } else if (animalCategory == 'Ovino' || animalCategory == 'Caprino') {
        pregnancyWeeks = 8 + rnd.nextInt(13); // 8-21 semanas
      } else if (animalCategory == 'Porcino') {
        pregnancyWeeks = 6 + rnd.nextInt(10); // 6-16 semanas
      } else if (animalCategory == 'Equino') {
        pregnancyWeeks = 15 + rnd.nextInt(33); // 15-48 semanas
      }
    } else if (rnd.nextInt(10) < 2) {
      isPregnant = false;
    }
    
    // Recomendaciones de alimentación específicas
    String? foodRecommendation;
    if (isPregnant == true) {
      foodRecommendation = 'Dieta alta en proteínas y minerales para gestación. Suplemento de calcio y energía. Agua fresca disponible.';
    } else if (hasDisease && diseaseName != null && diseaseName.contains('gastrointestinal')) {
      foodRecommendation = 'Dieta blanda y fácil digestión. Agua con electrolitos. Evitar alimentos ricos en fibra temporalmente.';
    } else if (health == 'mala') {
      foodRecommendation = 'Dieta nutritiva y balanceada. Alimentos altamente digestibles. Monitorear ingesta de agua.';
    } else {
      foodRecommendation = 'Continuar con dieta regular balanceada. Agua fresca disponible. Forraje de calidad.';
    }

    return ScanResult(
      id: _id(),
      ownerId: '', // Will be set when saving to Firestore
      createdAt: now,
      updatedAt: now,
      animalId: animalId,
      animalCategory: animalCategory,
      mode: mode,
      microchipNumber: mode == 'chip' ? (microchipNumber ?? 'CHIP-${100000 + rnd.nextInt(899999)}') : null,
      photosBase64: photoB64,
      healthStatus: health,
      diseaseName: diseaseName,
      fractureDescription: fractureDescription,
      medicationName: medicationName,
      medicationDose: medicationDose,
      isPregnant: isPregnant,
      pregnancyWeeks: pregnancyWeeks,
      foodRecommendation: foodRecommendation,
    );
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}
