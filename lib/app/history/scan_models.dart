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
  });

  final String id;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String animalId;
  final String animalCategory;
  final String mode; // chip | nochip
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

  Map<String, dynamic> toJson() => {
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
  };

  Map<String, dynamic> toFirestoreJson() => {
    'id': id,
    'ownerId': ownerId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
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
  };

  static ScanResult fromJson(Map<String, dynamic> json) {
    final photos = (json['photosBase64'] is List) 
        ? (json['photosBase64'] as List).map((e) => e.toString()).toList() 
        : <String>[];
    
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }
    
    return ScanResult(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      createdAt: parseDate(createdAtRaw),
      updatedAt: parseDate(updatedAtRaw),
      animalId: (json['animalId'] ?? '').toString(),
      animalCategory: (json['animalCategory'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      microchipNumber: json['microchipNumber']?.toString(),
      photosBase64: photos,
      healthStatus: (json['healthStatus'] ?? '').toString(),
      diseaseName: json['diseaseName']?.toString(),
      fractureDescription: json['fractureDescription']?.toString(),
      medicationName: json['medicationName']?.toString(),
      medicationDose: json['medicationDose']?.toString(),
      isPregnant: json['isPregnant'] is bool ? json['isPregnant'] as bool : null,
      pregnancyWeeks: json['pregnancyWeeks'] is num ? (json['pregnancyWeeks'] as num).toInt() : null,
      foodRecommendation: json['foodRecommendation']?.toString(),
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
    String? diseaseName,
    String? fractureDescription,
    String? medicationName,
    String? medicationDose,
    bool? isPregnant,
    int? pregnancyWeeks,
    String? foodRecommendation,
  }) => ScanResult(
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
  );
}
