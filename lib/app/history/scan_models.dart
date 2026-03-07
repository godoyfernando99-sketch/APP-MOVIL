import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResult {
  const ScanResult({
    required this.id,
    this.ownerId = '', // Opcional para evitar errores si no se provee
    required this.createdAt,
    this.updatedAt,
    required this.animalId,
    this.animalCategory = '',
    this.mode = 'nochip',
    this.microchipNumber,
    this.photosBase64 = const [],
    required this.healthStatus,
    this.detectedBreed,
    this.detectedSpecies,
    this.diseaseName,
    this.fractureDescription,
    this.medicationName,
    this.medicationDose,
    this.isPregnant,
    this.gestationWeeks, 
    this.foodRecommendation,
    this.observations,
    // --- NUEVOS CAMPOS PARA SOLUCIONAR EL ERROR DEL BUILD ---
    this.offspringCount,
    this.deliveryForecast,
    this.daysUntilDelivery,
    this.preventionTips = const [],
    this.medicationDays = const [],
    this.rescanInterval = 3,
  });

  final String id;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
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
  final String? gestationWeeks; 
  final String? foodRecommendation;
  final String? observations;

  // --- NUEVAS PROPIEDADES DE SEGUIMIENTO ---
  final String? offspringCount;
  final String? deliveryForecast;
  final int? daysUntilDelivery;
  final List<String> preventionTips;
  final List<int> medicationDays;
  final int rescanInterval;

  // --- GETTERS DE COMPATIBILIDAD ---
  String get animalType => (detectedSpecies?.isNotEmpty ?? false) 
      ? detectedSpecies! 
      : (animalCategory.isNotEmpty ? animalCategory : 'Animal');

  String get breed => (detectedBreed?.isNotEmpty ?? false) ? detectedBreed! : 'Raza no detectada';

  // --- MAPEO DE DATOS ---

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'animalId': animalId,
    'animalCategory': animalCategory,
    'mode': mode,
    'microchipNumber': microchipNumber,
    'photosBase64': photosBase64,
    'healthStatus': healthStatus,
    'detectedBreed': detectedBreed,
    'detectedSpecies': detectedSpecies,
    'isPregnant': isPregnant,
    'gestationWeeks': gestationWeeks,
    'offspringCount': offspringCount,
    'deliveryForecast': deliveryForecast,
    'daysUntilDelivery': daysUntilDelivery,
    'preventionTips': preventionTips,
    'medicationDays': medicationDays,
    'rescanInterval': rescanInterval,
    'observations': observations,
  };

  static ScanResult fromMap(Map<String, dynamic> map) {
    DateTime parse(dynamic r) {
      if (r is Timestamp) return r.toDate();
      if (r == null) return DateTime.now();
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
      healthStatus: map['healthStatus']?.toString() ?? 'regular',
      detectedBreed: map['detectedBreed']?.toString(),
      detectedSpecies: map['detectedSpecies']?.toString(),
      isPregnant: map['isPregnant'] == true,
      gestationWeeks: map['gestationWeeks']?.toString(),
      offspringCount: map['offspringCount']?.toString(),
      deliveryForecast: map['deliveryForecast']?.toString(),
      daysUntilDelivery: map['days_until_delivery'] as int?,
      preventionTips: List<String>.from(map['prevention_tips'] ?? []),
      medicationDays: List<int>.from(map['medication_days'] ?? []),
      rescanInterval: map['rescan_interval_days'] ?? 3,
      observations: map['observations']?.toString(),
    );
  }
}