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

  String get fullName => '$firstName $lastName'.trim();
  bool get isPro => subscriptionPlan == 'pro';
  bool get hasScansAvailable => scansRemaining > 0 || subscriptionPlan == 'pro';

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
  };

  static UserProfile fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
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
      scansRemaining: json['scansRemaining'] is num ? (json['scansRemaining'] as num).toInt() : 10,
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
  );
}
