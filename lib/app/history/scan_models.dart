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
    this.diseaseName,
    this.fractureDescription,
    this.medicationName,
    this.medicationDose,
    this.isPregnant,
    this.pregnancyWeeks,
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
  final String? diseaseName;
  final String? fractureDescription;
  final String? medicationName;
  final String? medicationDose;
  final bool? isPregnant;
  final int? pregnancyWeeks;
  final String? foodRecommendation;
  final String? observations;

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
    'diseaseName': diseaseName,
    'fractureDescription': fractureDescription,
    'medicationName': medicationName,
    'medicationDose': medicationDose,
    'isPregnant': isPregnant,
    'pregnancyWeeks': pregnancyWeeks,
    'foodRecommendation': foodRecommendation,
    'observations': observations,
  };

  static ScanResult fromMap(Map<String, dynamic> map) {
    DateTime parse(dynamic r) => r is Timestamp ? r.toDate() : (DateTime.tryParse(r.toString()) ?? DateTime.now());
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
      diseaseName: map['diseaseName']?.toString(),
      fractureDescription: map['fractureDescription']?.toString(),
      medicationName: map['medicationName']?.toString(),
      medicationDose: map['medicationDose']?.toString(),
      isPregnant: map['isPregnant'] as bool?,
      pregnancyWeeks: (map['pregnancyWeeks'] as num?)?.toInt(),
      foodRecommendation: map['foodRecommendation']?.toString(),
      observations: map['observations']?.toString(),
    );
  }

  ScanResult copyWith({
    String? id, String? ownerId, DateTime? createdAt, DateTime? updatedAt,
    String? animalId, String? animalCategory, String? mode, String? microchipNumber,
    List<String>? photosBase64, String? healthStatus, String? diseaseName,
    String? fractureDescription, String? medicationName, String? medicationDose,
    bool? isPregnant, int? pregnancyWeeks, String? foodRecommendation, String? observations,
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
      diseaseName: diseaseName ?? this.diseaseName,
      fractureDescription: fractureDescription ?? this.fractureDescription,
      medicationName: medicationName ?? this.medicationName,
      medicationDose: medicationDose ?? this.medicationDose,
      isPregnant: isPregnant ?? this.isPregnant,
      pregnancyWeeks: pregnancyWeeks ?? this.pregnancyWeeks,
      foodRecommendation: foodRecommendation ?? this.foodRecommendation,
      observations: observations ?? this.observations,
    );
  }
}
