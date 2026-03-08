import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para manejar el Timestamp de Firebase

class ScanResult {
  final String? id;
  final String? ownerId;
  final String animalType;
  final String healthStatus;
  final List<String> preventionTips;
  final bool isPregnant;
  
  // --- GESTACIÓN DETALLADA ---
  final String? offspringCount;
  final String? gestationWeeks;
  final int? daysUntilDelivery;
  final String? deliveryForecast;
  final String? totalGestationDuration; // REQUISITO: Cuánto dura el embarazo total

  // --- MEDICACIÓN Y TRATAMIENTO (Nuevos campos para tus requisitos) ---
  final int rescanInterval; // Para el control cada 3 días
  final List<int> medicationDays;
  final String? foodRecommendation; 
  final String suggestedFoodName; 
  final String? medicationDosage;   // REQUISITO: Cantidad de dosis
  final String? medicationRoute;    // REQUISITO: Via oral, ocular, inyección, etc.
  final String? applicationSite;    // REQUISITO: Lugar donde colocarlo

  final List<Uint8List> photos;
  final String? microchipId;        // REQUISITO: NFC Chip ID
  final DateTime timestamp;

  // Getters de compatibilidad para la UI
  DateTime get createdAt => timestamp;
  String get breed => animalType;
  bool get isUrgent => healthStatus.toUpperCase().contains('URGENTE'); 
  String? get diseaseName => isUrgent ? "ATENCIÓN ESPECIAL" : (healthStatus.toLowerCase().contains('sano') ? null : healthStatus);
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
    this.totalGestationDuration,
    this.rescanInterval = 3, // Por defecto cada 3 días como pediste
    this.medicationDays = const [],
    this.foodRecommendation,
    this.suggestedFoodName = "Dieta Balanceada",
    this.medicationDosage,
    this.medicationRoute,
    this.applicationSite,
    required this.photos,
    this.microchipId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // --- COPIAR OBJETO ---
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
      totalGestationDuration: totalGestationDuration,
      rescanInterval: rescanInterval,
      medicationDays: medicationDays,
      foodRecommendation: foodRecommendation,
      suggestedFoodName: suggestedFoodName,
      medicationDosage: medicationDosage,
      medicationRoute: medicationRoute,
      applicationSite: applicationSite,
      photos: photos,
      microchipId: microchipId,
      timestamp: timestamp,
    );
  }

  // --- A MAPA (Para Firebase y Local) ---
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
      'totalGestationDuration': totalGestationDuration,
      'rescanInterval': rescanInterval,
      'medicationDays': medicationDays,
      'foodRecommendation': foodRecommendation,
      'suggestedFoodName': suggestedFoodName,
      'medicationDosage': medicationDosage,
      'medicationRoute': medicationRoute,
      'applicationSite': applicationSite,
      'photosBase64': photosBase64,
      'microchipId': microchipId,
      'createdAt': timestamp.toIso8601String(),
    };
  }

  // --- DESDE MAPA ---
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
      totalGestationDuration: map['totalGestationDuration'],
      rescanInterval: map['rescanInterval'] ?? 3,
      medicationDays: List<int>.from(map['medicationDays'] ?? []),
      foodRecommendation: map['foodRecommendation'],
      suggestedFoodName: map['suggestedFoodName'] ?? "Dieta Balanceada",
      medicationDosage: map['medicationDosage'],
      medicationRoute: map['medicationRoute'],
      applicationSite: map['applicationSite'],
      photos: (map['photosBase64'] as List<dynamic>?)
              ?.map((e) => base64Decode(e as String))
              .toList() ?? [],
      microchipId: map['microchipId'],
      timestamp: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : (map['timestamp'] is Timestamp?) ? (map['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}