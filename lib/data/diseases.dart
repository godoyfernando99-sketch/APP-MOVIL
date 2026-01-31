class Disease {
  const Disease({
    required this.name,
    required this.description,
    required this.symptoms,
    required this.treatment,
    // Se eliminó la propiedad imagePath
  });

  final String name;
  final String description;
  final String symptoms;
  final String treatment;
}

class DiseasesCatalog {
  static const diseases = <Disease>[
    Disease(
      name: 'Parvovirosis',
      description: 'Enfermedad viral en perros. Provoca vómitos, diarrea y deshidratación severa.',
      symptoms: 'Vómitos frecuentes, diarrea con sangre, fiebre alta, letargo, pérdida de apetito',
      treatment: 'Hospitalización, fluidoterapia intravenosa, antibióticos para prevenir infecciones secundarias',
    ),
    Disease(
      name: 'Moquillo',
      description: 'Enfermedad viral que afecta sistema respiratorio y nervioso en perros.',
      symptoms: 'Fiebre, secreción nasal, tos, vómitos, diarrea, convulsiones, parálisis',
      treatment: 'No hay cura específica. Tratamiento de soporte, antibióticos, anticonvulsivantes',
    ),
    Disease(
      name: 'Leptospirosis',
      description: 'Bacteria que puede afectar riñones e hígado. Riesgo zoonótico.',
      symptoms: 'Fiebre, vómitos, debilidad muscular, dolor abdominal, insuficiencia renal',
      treatment: 'Antibióticos (doxiciclina, penicilina), fluidoterapia, tratamiento de soporte',
    ),
    Disease(
      name: 'Sarna',
      description: 'Afección de la piel por ácaros. Causa picazón intensa y pérdida de pelo.',
      symptoms: 'Picazón severa, pérdida de pelo, enrojecimiento de la piel, costras, infecciones secundarias',
      treatment: 'Medicamentos antiparasitarios, baños medicados, antibióticos si hay infección',
    ),
    Disease(
      name: 'Anemia',
      description: 'Disminución de glóbulos rojos; puede causar debilidad y mucosas pálidas.',
      symptoms: 'Encías pálidas, debilidad, letargo, pérdida de apetito, respiración rápida',
      treatment: 'Depende de la causa: transfusiones, suplementos de hierro, tratamiento de enfermedad subyacente',
    ),
    Disease(
      name: 'Mastitis (ganado)',
      description: 'Inflamación de la ubre. Produce dolor y cambios en la leche.',
      symptoms: 'Ubre inflamada y caliente, dolor al tacto, leche con grumos o sangre, fiebre',
      treatment: 'Antibióticos, antiinflamatorios, ordeño frecuente, compresas frías',
    ),
    Disease(
      name: 'Fiebre aftosa',
      description: 'Enfermedad viral del ganado con lesiones en boca y patas.',
      symptoms: 'Fiebre alta, ampollas en boca, lengua, patas, salivación excesiva, cojera',
      treatment: 'No hay tratamiento específico. Cuidados de soporte, aislamiento, vacunación preventiva',
    ),
    Disease(
      name: 'Coccidiosis',
      description: 'Parásitos intestinales; diarrea y pérdida de peso en aves y mamíferos jóvenes.',
      symptoms: 'Diarrea acuosa o con sangre, deshidratación, pérdida de peso, debilidad',
      treatment: 'Medicamentos anticoccidiales, fluidoterapia, mantener higiene del entorno',
    ),
    Disease(
      name: 'Rabia',
      description: 'Enfermedad viral mortal que afecta el sistema nervioso. Zoonótica.',
      symptoms: 'Cambios de comportamiento, agresividad, salivación excesiva, parálisis, convulsiones',
      treatment: 'No hay tratamiento. Fatal una vez que aparecen los síntomas. Prevención mediante vacunación',
    ),
    Disease(
      name: 'Brucelosis',
      description: 'Infección bacteriana que causa abortos en ganado. Zoonótica.',
      symptoms: 'Abortos, retención de placenta, inflamación testicular, infertilidad',
      treatment: 'Antibióticos prolongados, sacrificio de animales infectados en programas de control',
    ),
    Disease(
      name: 'Leucemia Felina',
      description: 'Virus que debilita el sistema inmune de los gatos.',
      symptoms: 'Pérdida de peso, anemia, infecciones recurrentes, linfomas, letargo',
      treatment: 'No hay cura. Tratamiento de soporte, prevenir infecciones secundarias',
    ),
    Disease(
      name: 'Gusano del corazón',
      description: 'Parásito que afecta el corazón y pulmones de perros y gatos.',
      symptoms: 'Tos, dificultad respiratoria, fatiga, pérdida de peso, insuficiencia cardíaca',
      treatment: 'Medicamentos antiparasitarios, reposo estricto, prevención mensual',
    ),
    Disease(
      name: 'Tuberculosis Bovina',
      description: 'Enfermedad bacteriana crónica que afecta principalmente pulmones.',
      symptoms: 'Tos crónica, pérdida de peso, debilidad, ganglios linfáticos inflamados',
      treatment: 'Sacrificio de animales infectados, pruebas regulares, vacunación',
    ),
    Disease(
      name: 'Influenza Aviar',
      description: 'Virus altamente contagioso que afecta aves de corral.',
      symptoms: 'Reducción en producción de huevos, dificultad respiratoria, hinchazón, muerte súbita',
      treatment: 'No hay tratamiento. Sacrificio sanitario, bioseguridad, vacunación preventiva',
    ),
    Disease(
      name: 'Enfermedad de Newcastle',
      description: 'Enfermedad viral contagiosa en aves.',
      symptoms: 'Dificultad respiratoria, diarrea verde, tortícolis, parálisis, muerte',
      treatment: 'No hay tratamiento específico. Vacunación preventiva, bioseguridad',
    ),
  ];
}
