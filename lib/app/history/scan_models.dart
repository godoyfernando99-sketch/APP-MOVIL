import 'dart:typed_data';

class ScanResult {
  final String? id; // Identificador único para el historial
  final String animalType;
  final String healthStatus;
  final List<String> preventionTips;
  final bool isPregnant;
  
  // Datos de Gestación
  final String? offspringCount;
  final String? gestationWeeks;
  final int? daysUntilDelivery;
  final String? deliveryForecast;

  // Seguimiento e IA
  final int rescanInterval;
  final List<int> medicationDays;
  final String? foodRecommendation; 
  final String suggestedFoodName; 

  // Metadatos
  final List<Uint8List> photos;
  final String? microchipId;
  final DateTime timestamp;

  ScanResult({
    this.id,
    required this.animalType,
    required this.healthStatus,
    required this.preventionTips,
    this.isPregnant = false,
    this.offspringCount,
    this.gestationWeeks,
    this.daysUntilDelivery,
    this.deliveryForecast,
    this.rescanInterval = 7,
    this.medicationDays = const [],
    this.foodRecommendation,
    this.suggestedFoodName = "Dieta Balanceada",
    required this.photos,
    this.microchipId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id']?.toString(),
      animalType: json['animalType'] ?? 'Desconocido',
      healthStatus: json['healthStatus'] ?? 'No disponible',
      preventionTips: List<String>.from(json['preventionTips'] ?? []),
      isPregnant: json['isPregnant'] ?? false,
      offspringCount: json['offspringCount']?.toString(),
      gestationWeeks: json['gestationWeeks']?.toString(),
      daysUntilDelivery: json['daysUntilDelivery'],
      deliveryForecast: json['deliveryForecast'],
      rescanInterval: json['rescanInterval'] ?? 7,
      medicationDays: List<int>.from(json['medicationDays'] ?? []),
      foodRecommendation: json['foodRecommendation'],
      suggestedFoodName: json['suggestedFoodName'] ?? "Dieta Balanceada",
      photos: [], 
      microchipId: json['microchipId'],
    );
  }
}