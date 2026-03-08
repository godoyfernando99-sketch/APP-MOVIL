import 'dart:typed_data';
import 'dart:convert';

class ScanResult {
  final String? id;
  final String? ownerId;
  final String animalType;
  final String healthStatus;
  final List<String> preventionTips;
  final bool isPregnant;
  
  final String? offspringCount;
  final String? gestationWeeks;
  final int? daysUntilDelivery;
  final String? deliveryForecast;

  final int rescanInterval;
  final List<int> medicationDays;
  final String? foodRecommendation; 
  final String suggestedFoodName; 

  final List<Uint8List> photos;
  final String? microchipId;
  final DateTime timestamp;

  // Getters de compatibilidad para la UI
  DateTime get createdAt => timestamp;
  String get breed => animalType;
  String? get diseaseName => healthStatus.toLowerCase().contains('sano') ? null : healthStatus;
  String? get microchipNumber => microchipId;
  List<String> get photosBase64 => photos.map((p) => base64Encode(p)).toList();

  ScanResult({
    this.id,
    this.ownerId,
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

  // --- MÉTODO PARA COPIAR EL OBJETO (Requerido por Controller) ---
  ScanResult copyWith({String? ownerId, String? id}) {
    return ScanResult(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      animalType: animalType,
      healthStatus: healthStatus,
      preventionTips: preventionTips,
      isPregnant: isPregnant,
      offspringCount: offspringCount,
      gestationWeeks: gestationWeeks,
      daysUntilDelivery: daysUntilDelivery,
      deliveryForecast: deliveryForecast,
      rescanInterval: rescanInterval,
      medicationDays: medicationDays,
      foodRecommendation: foodRecommendation,
      suggestedFoodName: suggestedFoodName,
      photos: photos,
      microchipId: microchipId,
      timestamp: timestamp,
    );
  }

  // --- CONVERTIR A MAP PARA FIREBASE/LOCAL (Requerido por Controller) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'animalType': animalType,
      'healthStatus': healthStatus,
      'preventionTips': preventionTips,
      'isPregnant': isPregnant,
      'offspringCount': offspringCount,
      'gestationWeeks': gestationWeeks,
      'daysUntilDelivery': daysUntilDelivery,
      'deliveryForecast': deliveryForecast,
      'rescanInterval': rescanInterval,
      'medicationDays': medicationDays,
      'foodRecommendation': foodRecommendation,
      'suggestedFoodName': suggestedFoodName,
      'photosBase64': photosBase64, // Guardamos como string en local
      'microchipId': microchipId,
      'createdAt': timestamp.toIso8601String(),
    };
  }

  // --- CREAR DESDE MAP (Requerido por Controller) ---
  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'],
      ownerId: map['ownerId'],
      animalType: map['animalType'] ?? 'Desconocido',
      healthStatus: map['healthStatus'] ?? 'No disponible',
      preventionTips: List<String>.from(map['preventionTips'] ?? []),
      isPregnant: map['isPregnant'] ?? false,
      offspringCount: map['offspringCount'],
      gestationWeeks: map['gestationWeeks'],
      daysUntilDelivery: map['daysUntilDelivery'],
      deliveryForecast: map['deliveryForecast'],
      rescanInterval: map['rescanInterval'] ?? 7,
      medicationDays: List<int>.from(map['medicationDays'] ?? []),
      foodRecommendation: map['foodRecommendation'],
      suggestedFoodName: map['suggestedFoodName'] ?? "Dieta Balanceada",
      photos: (map['photosBase64'] as List<dynamic>?)
              ?.map((e) => base64Decode(e as String))
              .toList() ?? [],
      microchipId: map['microchipId'],
      timestamp: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}