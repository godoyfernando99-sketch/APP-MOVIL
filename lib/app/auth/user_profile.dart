import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.birthDateIso,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionPlan = 'free',
    this.monthlyScans = 10, // Cambiado de scansRemaining a monthlyScans
    this.lastReset,
  });

  final String uid;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String birthDateIso;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String subscriptionPlan;
  final int monthlyScans; // Este es el campo que pedía el MainMenuPage
  final DateTime? lastReset;

  // --- GETTERS DE LÓGICA DE NEGOCIO ---

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => username.isNotEmpty ? username : firstName;
  
  // Soporte VIP para planes específicos
  bool get hasVipSupport => subscriptionPlan == 'basico' || subscriptionPlan == 'premium';
  
  // Determina si puede escanear
  bool get hasScansAvailable => subscriptionPlan == 'premium' || monthlyScans > 0;

  // Límites mensuales según el plan
  int get maxScansByPlan {
    switch (subscriptionPlan) {
      case 'basico': return 15;
      case 'premium': return 999999; // Escaneos ilimitados
      default: return 10; // Plan Free
    }
  }

  // --- MAPEO DE DATOS ---

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'birthDateIso': birthDateIso,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'subscriptionPlan': subscriptionPlan,
    'monthlyScans': monthlyScans,
    'lastReset': lastReset != null ? Timestamp.fromDate(lastReset!) : null,
  };

  static UserProfile fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    final lastResetRaw = json['lastReset'];

    return UserProfile(
      uid: (json['uid'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      birthDateIso: (json['birthDateIso'] ?? '').toString(),
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now(),
      updatedAt: updatedAtRaw is Timestamp ? updatedAtRaw.toDate() : DateTime.now(),
      subscriptionPlan: (json['subscriptionPlan'] ?? 'free').toString(),
      monthlyScans: json['monthlyScans'] is num 
          ? (json['monthlyScans'] as num).toInt() 
          : (json['scansRemaining'] ?? 10), // Fallback por si en Firebase aún se llama scansRemaining
      lastReset: lastResetRaw is Timestamp ? lastResetRaw.toDate() : null,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? birthDateIso,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subscriptionPlan,
    int? monthlyScans,
    DateTime? lastReset,
  }) => UserProfile(
    uid: uid ?? this.uid,
    username: username ?? this.username,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    birthDateIso: birthDateIso ?? this.birthDateIso,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    monthlyScans: monthlyScans ?? this.monthlyScans,
    lastReset: lastReset ?? this.lastReset,
  );
}
