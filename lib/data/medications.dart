class Medication {
  const Medication({
    required this.name,
    required this.forWhat,
    required this.doseHint,
    required this.activeIngredient,
    required this.sideEffects,
    required this.imagePath,
  });
  final String name;
  final String forWhat;
  final String doseHint;
  final String activeIngredient;
  final String sideEffects;
  final String imagePath;
}

class MedicationsCatalog {
  static const medications = <Medication>[
    Medication(
      name: 'Amoxicilina',
      forWhat: 'Antibiótico para infecciones bacterianas.',
      doseHint: 'Según peso del animal (consulta veterinaria).',
      activeIngredient: 'Amoxicilina trihidrato',
      sideEffects: 'Náuseas, diarrea, reacciones alérgicas',
      imagePath: 'assets/images/Amoxicillin_pills_medicine_null_1769174409959.jpg',
    ),
    Medication(
      name: 'Ivermectina',
      forWhat: 'Antiparasitario (ácaros, parásitos externos e internos).',
      doseHint: 'Dosis depende de especie/peso. No usar en razas sensibles sin supervisión.',
      activeIngredient: 'Ivermectina',
      sideEffects: 'Toxicidad en razas sensibles, letargo, vómitos',
      imagePath: 'assets/images/Ivermectin_medication_null_1769174411341.jpg',
    ),
    Medication(
      name: 'Meloxicam',
      forWhat: 'Antiinflamatorio/analgésico para dolor y cojera.',
      doseHint: 'Ajustar por especie y condición renal.',
      activeIngredient: 'Meloxicam',
      sideEffects: 'Problemas gastrointestinales, insuficiencia renal',
      imagePath: 'assets/images/Meloxicam_pills_null_1769174412176.jpg',
    ),
    Medication(
      name: 'Electrolitos orales',
      forWhat: 'Rehidratación en diarreas y golpes de calor.',
      doseHint: 'Administración fraccionada y frecuente.',
      activeIngredient: 'Sodio, potasio, glucosa',
      sideEffects: 'Raros, posible sobrehidratación si se excede',
      imagePath: 'assets/images/Oral_electrolytes_solution_null_1769174413282.jpg',
    ),
    Medication(
      name: 'Oxitetraciclina',
      forWhat: 'Antibiótico de amplio espectro en ganado.',
      doseHint: 'Uso veterinario; respetar retiro en producción.',
      activeIngredient: 'Oxitetraciclina',
      sideEffects: 'Fotosensibilidad, reacciones locales, diarrea',
      imagePath: 'assets/images/Oxytetracycline_antibiotic_null_1769174414033.jpg',
    ),
    Medication(
      name: 'Dexametasona',
      forWhat: 'Corticosteroide antiinflamatorio potente.',
      doseHint: 'Dosis debe ser prescrita por veterinario.',
      activeIngredient: 'Dexametasona',
      sideEffects: 'Aumento de sed, apetito, supresión inmune prolongada',
      imagePath: 'assets/images/ai_generated_1769158907214.jpg',
    ),
    Medication(
      name: 'Cefalexina',
      forWhat: 'Antibiótico para infecciones de piel y tejidos blandos.',
      doseHint: 'Administrar cada 8-12 horas según prescripción.',
      activeIngredient: 'Cefalexina',
      sideEffects: 'Vómitos, diarrea, reacciones alérgicas',
      imagePath: 'assets/images/ai_generated_1769158602687.jpg',
    ),
    Medication(
      name: 'Metronidazol',
      forWhat: 'Antibiótico y antiparasitario para infecciones intestinales.',
      doseHint: 'Dosis según peso, administrar con alimento.',
      activeIngredient: 'Metronidazol',
      sideEffects: 'Sabor amargo, náuseas, efectos neurológicos en altas dosis',
      imagePath: 'assets/images/ai_generated_1769158667040.jpg',
    ),
    Medication(
      name: 'Fipronil',
      forWhat: 'Control de pulgas y garrapatas.',
      doseHint: 'Aplicación tópica mensual.',
      activeIngredient: 'Fipronil',
      sideEffects: 'Irritación cutánea, vómitos si se ingiere',
      imagePath: 'assets/images/ai_generated_1769158692690.jpg',
    ),
    Medication(
      name: 'Enrofloxacina',
      forWhat: 'Antibiótico fluoroquinolona para diversas infecciones.',
      doseHint: 'No usar en animales jóvenes en crecimiento.',
      activeIngredient: 'Enrofloxacina',
      sideEffects: 'Problemas articulares en cachorros, vómitos',
      imagePath: 'assets/images/ai_generated_1769158749542.jpg',
    ),
    Medication(
      name: 'Omeprazol',
      forWhat: 'Reductor de ácido estomacal para úlceras.',
      doseHint: 'Administrar con estómago vacío, una vez al día.',
      activeIngredient: 'Omeprazol',
      sideEffects: 'Diarrea, cambios en apetito',
      imagePath: 'assets/images/ai_generated_1769158782076.jpg',
    ),
    Medication(
      name: 'Carprofeno',
      forWhat: 'Antiinflamatorio no esteroide para perros.',
      doseHint: 'Dar con alimento para reducir irritación gástrica.',
      activeIngredient: 'Carprofeno',
      sideEffects: 'Problemas gastrointestinales, hepáticos o renales',
      imagePath: 'assets/images/ai_generated_1769158827146.jpg',
    ),
  ];
}
