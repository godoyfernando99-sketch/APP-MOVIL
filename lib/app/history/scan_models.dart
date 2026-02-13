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

  /// Convierte el objeto a un Map estándar (JSON)
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

  /// Convierte el objeto específicamente para Firebase Cloud Firestore
  Map<String, dynamic> toFirestoreMap() {
    final map = toMap();
    map['createdAt'] = Timestamp.fromDate(createdAt);
    map['updatedAt'] = Timestamp.fromDate(updatedAt);
    return map;
  }

  /// Crea una instancia de ScanResult desde un Map (Firestore o JSON)
  static ScanResult fromMap(Map<String, dynamic> map) {
    // Manejo seguro de la lista de fotos
    final photos = (map['photosBase64'] is List)
        ? List<String>.from(map['photosBase64'])
        : <String>[];

    // Helper para parsear fechas de forma flexible (Timestamp o String)
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
      isPregnant: map['isPregnant'] is bool ? map['isPregnant'] as bool : null,
      pregnancyWeeks: (map['pregnancyWeeks'] as num?)?.toInt(),
      foodRecommendation: map['foodRecommendation']?.toString(),
      observations: map['observations']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  static ScanResult fromJson(Map<String, dynamic> json) => fromMap(json);

  /// Crea una copia del objeto cambiando solo los parámetros necesarios
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
    String? observations,
  }) {
    return ScanResult(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt
