import 'dart:typed_data';

class ScanResult {
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
  
  // --- EL CAMPO QUE FALTABA ---
  final String suggestedFoodName; 

  // Metadatos de la captura
  final List<Uint8List> photos;
  final String? microchipId;
  final DateTime timestamp;

  ScanResult({
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
    // Valor por defecto para evitar errores si la IA no lo envía
    this.suggestedFoodName = "Dieta Nutricional Estándar", 
    required this.photos,
    this.microchipId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Método para convertir de JSON (útil si usas Firebase o una API de IA)
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
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
      suggestedFoodName: json['suggestedFoodName'] ?? "Dieta Nutricional Estándar",
      photos: [], // Las fotos suelen manejarse por separado del JSON puro
      microchipId: json['microchipId'],
    );
  }
}