import 'dart:typed_data';
import 'dart:convert';

class ScanResult {
  final String? id;
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

  // Metadatos y Compatibilidad con HistoryPage
  final List<Uint8List> photos;
  final String? microchipId;
  final DateTime timestamp;

  // --- GETTERS DE COMPATIBILIDAD PARA HISTORY PAGE ---
  DateTime get createdAt => timestamp;
  String get breed => animalType; // Mapeo simple para evitar error de 'breed'
  String? get diseaseName => healthStatus.contains('SANO') ? null : healthStatus;
  String? get microchipNumber => microchipId;
  
  // Convierte las fotos de bytes a Base64 para el historial si es necesario
  List<String> get photosBase64 => photos.map((p) => base64Encode(p)).toList();

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
      photos: [], // Nota: Las fotos suelen persistirse como rutas o base64 en local
      microchipId: json['microchipId'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }
}