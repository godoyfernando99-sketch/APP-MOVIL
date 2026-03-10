import 'dart:typed_data';
import 'dart:convert';

class ScanResult {
  final String id;
  final String? ownerId;
  final String animalType;
  final String? breed;
  final String healthStatus;
  final List<String> preventionTips;
  final bool isPregnant;
  final bool isHighRisk; // AGREGADO: Vital para alertas de tumores/cáncer
  final String? offspringCount;
  final String? gestationWeeks;
  final String? totalGestationDuration;
  final int? daysUntilDelivery;
  final int rescanInterval;
  final String? medicationDosage;
  final String? medicationRoute;
  final String? applicationSite;
  final String suggestedFoodName;
  final String? foodRecommendation;
  final List<Uint8List> photos;
  final String? microchipId;
  final DateTime timestamp;
  final String? notes;

  ScanResult({
    required this.id,
    this.ownerId,
    required this.animalType,
    this.breed,
    required this.healthStatus,
    required this.preventionTips,
    required this.isPregnant,
    this.isHighRisk = false, // AGREGADO
    this.offspringCount,
    this.gestationWeeks,
    this.totalGestationDuration,
    this.daysUntilDelivery,
    required this.rescanInterval,
    this.medicationDosage,
    this.medicationRoute,
    this.applicationSite,
    required this.suggestedFoodName,
    this.foodRecommendation,
    required this.photos,
    this.microchipId,
    required this.timestamp,
    this.notes,
  });

  DateTime get createdAt => timestamp;

  // Lógica mejorada: es urgente si es HighRisk o si el texto lo dice
  bool get isUrgent => isHighRisk || healthStatus.toUpperCase().contains('URGENTE');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'animalType': animalType,
      'breed': breed,
      'healthStatus': healthStatus,
      'preventionTips': preventionTips,
      'isPregnant': isPregnant,
      'isHighRisk': isHighRisk, // AGREGADO
      'offspringCount': offspringCount,
      'gestationWeeks': gestationWeeks,
      'totalGestationDuration': totalGestationDuration,
      'daysUntilDelivery': daysUntilDelivery,
      'rescanInterval': rescanInterval,
      'medicationDosage': medicationDosage,
      'medicationRoute': medicationRoute,
      'applicationSite': applicationSite,
      'suggestedFoodName': suggestedFoodName,
      'foodRecommendation': foodRecommendation,
      'microchipId': microchipId,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'photosBase64': photos.map((e) => base64Encode(e)).toList(),
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] ?? '',
      ownerId: map['ownerId'],
      animalType: map['animalType'] ?? '',
      breed: map['breed'] ?? map['detectedBreed'], 
      healthStatus: map['healthStatus'] ?? '',
      preventionTips: List<String>.from(map['preventionTips'] ?? []),
      isPregnant: map['isPregnant'] ?? false,
      isHighRisk: map['isHighRisk'] ?? false, // AGREGADO
      offspringCount: map['offspringCount'],
      gestationWeeks: map['gestationWeeks'],
      totalGestationDuration: map['totalGestationDuration'],
      daysUntilDelivery: map['daysUntilDelivery'],
      rescanInterval: map['rescanInterval'] ?? 3,
      medicationDosage: map['medicationDosage'],
      medicationRoute: map['medicationRoute'],
      applicationSite: map['applicationSite'],
      suggestedFoodName: map['suggestedFoodName'] ?? '',
      foodRecommendation: map['foodRecommendation'],
      microchipId: map['microchipId'] ?? map['microchipNumber'],
      notes: map['notes'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      photos: (map['photosBase64'] as List?)?.map((e) => base64Decode(e)).toList() ?? [],
    );
  }

  // Agregamos isHighRisk al copyWith para que el controlador no lo pierda
  ScanResult copyWith({String? ownerId, String? notes, bool? isHighRisk}) {
    return ScanResult(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      animalType: animalType,
      breed: breed,
      healthStatus: healthStatus,
      preventionTips: preventionTips,
      isPregnant: isPregnant,
      isHighRisk: isHighRisk ?? this.isHighRisk, // AGREGADO
      offspringCount: offspringCount,
      gestationWeeks: gestationWeeks,
      totalGestationDuration: totalGestationDuration,
      daysUntilDelivery: daysUntilDelivery,
      rescanInterval: rescanInterval,
      medicationDosage: medicationDosage,
      medicationRoute: medicationRoute,
      applicationSite: applicationSite,
      suggestedFoodName: suggestedFoodName,
      foodRecommendation: foodRecommendation,
      photos: photos,
      microchipId: microchipId,
      timestamp: timestamp,
      notes: notes ?? this.notes,
    );
  }
}