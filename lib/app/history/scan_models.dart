import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResult {
  const ScanResult({
    required this.id,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.animalId,
    required this.animalCategory,
    required this.mode,
    this.microchipNumber,
    required this.photosBase64,
    required this.healthStatus,
    this.detectedBreed,
    this.detectedSpecies,
    this.diseaseName,
    this.fractureDescription,
    this.medicationName,
    this.medicationDose,
    this.isPregnant,
    this.gestationWeeks, // <--- Cambio de int a String para mayor detalle (ej: "45 días")
    this.foodRecommendation,
    this.observations, 
  });

  final String id;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String animalId;
  final String animalCategory;
  final String mode; 
  final String? microchipNumber;
  final List<String> photosBase64;
  final String healthStatus;
  final String? detectedBreed;
  final String? detectedSpecies;
  final String? diseaseName;
  final String? fractureDescription;
  final String? medicationName;
  final String? medicationDose;
  final bool? isPregnant;
  final String? gestationWeeks; // <--- String para soportar "3 semanas" o "40 días"
  final String? foodRecommendation;
  final String? observations;

  // Getter para mantener compatibilidad con código antiguo si usabas pregnancyWeeks
  String? get pregnancyWeeks => gestationWeeks;

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'animalId': animalId,
    'animalCategory': animalCategory,
    'mode': mode,
    'microchipNumber': microchipNumber,
    'photosBase64': photosBase64,
    'healthStatus': healthStatus,
    'detectedBreed': detectedBreed,
    'detectedSpecies': detectedSpecies,
    'diseaseName': diseaseName,
    'fractureDescription': fractureDescription,
    'medicationName': medicationName,
    'medicationDose': medicationDose,
    'isPregnant': isPregnant,
    'gestationWeeks': gestationWeeks,
    'foodRecommendation': foodRecommendation,
    'observations': observations,
  };

  static ScanResult fromMap(Map<String, dynamic> map) {
    DateTime parse(dynamic r) {
      if (r is Timestamp) return r.toDate();
      return DateTime.tryParse(r.toString()) ?? DateTime.now();
    }
    return ScanResult(
      id: map['id']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      createdAt: parse(map['createdAt']),
      updatedAt: parse(map['updatedAt']),
      animalId: map['animalId']?.toString() ?? '',
      animalCategory: map['animalCategory']?.toString() ?? '',
      mode: map['mode']?.toString() ?? 'nochip',
      microchipNumber: map['microchipNumber']?.toString(),
      photosBase64: List<String>.from(map['photosBase64'] ?? []),
      healthStatus: map['healthStatus']?.toString() ?? 'buena',
      detectedBreed: map['detectedBreed']?.toString(),
      detectedSpecies: map['detectedSpecies']?.toString(),
      diseaseName: map['diseaseName']?.toString(),
      fractureDescription: map['fractureDescription']?.toString(),
      medicationName: map['medicationName']?.toString(),
      medicationDose: map['medicationDose']?.toString(),
      isPregnant: map['isPregnant'] as bool?,
      // Convertimos a String cualquier valor que venga para evitar errores de tipo
      gestationWeeks: map['gestationWeeks']?.toString() ?? map['pregnancyWeeks']?.toString(),
      foodRecommendation: map['foodRecommendation']?.toString(),
      observations: map['observations']?.toString(),
    );
  }

  ScanResult copyWith({
    String? id,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? animalId,
    String? animalCategory,
    String? mode,
    String? microchipNumber,
    List<String>? photosBase64,
    String? healthStatus,
    String? detectedBreed,
    String? detectedSpecies,
    String? diseaseName,
    String? fractureDescription,
    String? medicationName,
    String? medicationDose,
    bool? isPregnant,
    String? gestationWeeks,
    String? foodRecommendation,
    String? observations,
  }) {
    return ScanResult(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      animalId: animalId ?? this.animalId,
      animalCategory: animalCategory ?? this.animalCategory,
      mode: mode ?? this.mode,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      photosBase64: photosBase64 ?? this.photosBase64,
      healthStatus: healthStatus ?? this.healthStatus,
      detectedBreed: detectedBreed ?? this.detectedBreed,
      detectedSpecies: detectedSpecies ?? this.detectedSpecies,
      diseaseName: diseaseName ?? this.diseaseName,
      fractureDescription: fractureDescription ?? this.fractureDescription,
      medicationName: medicationName ?? this.medicationName,
      medicationDose: medicationDose ?? this.medicationDose,
      isPregnant: isPregnant ?? this.isPregnant,
      gestationWeeks: gestationWeeks ?? this.gestationWeeks,
      foodRecommendation: foodRecommendation ?? this.foodRecommendation,
      observations: observations ?? this.observations,
    );
  }
}
