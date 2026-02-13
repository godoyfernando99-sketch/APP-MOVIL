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
    this.scansRemaining = 10,
    this.lastReset, // Nueva fecha para control de renovación mensual
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
  final int scansRemaining;
  final DateTime? lastReset; // Controla el ciclo de 30 días

  // --- GETTERS DE LÓGICA DE NEGOCIO ---

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => username.isNotEmpty ? username : firstName;
  
  // El Plan Pro es el único con acceso a Soporte VIP
  bool get isPro => subscriptionPlan == 'pro';
  
  // Determina si puede escanear
  bool get hasScansAvailable => subscriptionPlan == 'pro' || scansRemaining > 0;

  // Retorna el máximo de escaneos según el plan para la renovación
  int get maxScansByPlan {
    switch (subscriptionPlan) {
      case 'basic': return 15;
      case 'intermediate': return 30; // Plan Premium
      case 'pro': return 999999;
      default: return 10; // Plan Free de bienvenida
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
    'scansRemaining': scansRemaining,
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
      scansRemaining: json['scansRemaining'] is num 
          ? (json['scansRemaining'] as num).toInt() 
          : 10,
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
    int? scansRemaining,
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
    scansRemaining: scansRemaining ?? this.scansRemaining,
    lastReset: lastReset ?? this.lastReset,
  );
}
