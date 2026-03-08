import 'dart:typed_data';

class ScanResult {
  final String id;
  final String animalType;
  final String? breed;
  final String healthStatus;
  final List<String> preventionTips;
  final bool isPregnant;
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

  ScanResult({
    required this.id,
    required this.animalType,
    this.breed,
    required this.healthStatus,
    required this.preventionTips,
    required this.isPregnant,
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
  });

  // Helper para saber si es urgente y activar vibración/alertas
  bool get isUrgent => healthStatus.toUpperCase().contains('URGENTE');

  // Helper para los días de medicación (usado en NotificationService)
  List<int> get medicationDays => [1, 3, 5, 7]; // Por defecto o personalizable
}