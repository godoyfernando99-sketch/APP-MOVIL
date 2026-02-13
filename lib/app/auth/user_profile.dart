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
    this.monthlyScans = 10, 
    this.lastReset,
    // --- SOLUCIÓN AL ERROR: Parámetro opcional en el constructor ---
    int? scansRemaining, 
  }) : _scansRemainingParam = scansRemaining;

  final String uid;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String birthDateIso;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String subscriptionPlan;
  final int monthlyScans; 
  final DateTime? lastReset;
  final int? _scansRemainingParam; // Variable interna temporal

  // --- GETTERS DE COMPATIBILIDAD ---

  // Si se pasó 'scansRemaining' al constructor, lo usamos; si no, usamos 'monthlyScans'
  int get scansRemaining => _scansRemainingParam ?? monthlyScans;

  bool get isPro => subscriptionPlan.toLowerCase() == 'pro' || subscriptionPlan.toLowerCase() == 'premium';

  // --- GETTERS DE LÓGICA DE NEGOCIO ---

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => username.isNotEmpty ? username : firstName;
  
  bool get hasVipSupport => subscriptionPlan == 'basico' || subscriptionPlan == 'premium';
  
  bool get hasScansAvailable => isPro || scansRemaining > 0;

  int get maxScansByPlan {
    switch (subscriptionPlan.toLowerCase()) {
      case 'basico': return 15;
      case 'premium': return 999999; 
      case 'pro': return 999999;
      default: return 10; 
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

    int scans = 10;
    if (json['monthlyScans'] != null) {
      scans = (json['monthlyScans'] as num).toInt();
    } else if (json['scansRemaining'] != null) {
      scans = (json['scansRemaining'] as num).toInt();
    }

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
      monthlyScans: scans,
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
    monthlyScans: monthlyScans ?? this.monthlyScans,
    scansRemaining: scansRemaining ?? this.scansRemaining,
    lastReset: lastReset ?? this.lastReset,
  );
}
