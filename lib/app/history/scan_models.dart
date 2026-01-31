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

  // Cambiado de toJson a toMap para consistencia con el Controller
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
      };

  // Método específico para Firestore que maneja los Timestamps nativos
  Map<String, dynamic> toFirestoreMap() {
    final map = toMap();
    map['createdAt'] = Timestamp.fromDate(createdAt);
    map['updatedAt'] = Timestamp.fromDate(updatedAt);
    return map;
  }

  // Cambiado de fromJson a fromMap
  static ScanResult fromMap(Map<String, dynamic> map) {
    final photos = (map['photosBase64'] is List)
        ? List<String>.from(map['photosBase64'])
        : <String>[];

    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return ScanResult(
      id: map['id']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      animalId: map['animalId']?.toString() ?? '',
      animalCategory: map['animalCategory']?.toString() ?? '',
      mode: map['mode']?.toString() ?? 'nochip',
      microchipNumber: map['microchipNumber']?.toString(),
      photosBase64: photos,
      healthStatus: map['healthStatus']?.toString() ?? 'desconocida',
      diseaseName: map['diseaseName']?.toString(),
      fractureDescription: map['fractureDescription']?.toString(),
      medicationName: map['medicationName']?.toString(),
      medicationDose: map['medicationDose']?.toString(),
      isPregnant: map['isPregnant'] as bool?,
      pregnancyWeeks: (map['pregnancyWeeks'] as num?)?.toInt(),
      foodRecommendation: map['foodRecommendation']?.toString(),
    );
  }

  // Mantenemos los alias para evitar errores si otras partes del código los usan
  Map<String, dynamic> toJson() => toMap();
  static ScanResult fromJson(Map<String, dynamic> json) => fromMap(json);

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
    );
  }
}
