import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:scanneranimal/app/auth/user_profile.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    try {
      _initGoogleSignIn();
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          _currentUser = null;
          notifyListeners();
        } else {
          _loadUserProfile(user.uid);
        }
      });
    } catch (e) {
      debugPrint('AuthController initialization failed: $e');
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;

  void _initGoogleSignIn() {
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: '71382402825-95402b132c675faf79f5d8.apps.googleusercontent.com',
        scopes: ['email'],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
    }
  }

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null && (_auth.currentUser?.emailVerified ?? false);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      }
    } catch (e) {
      debugPrint('AuthController.init failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserProfile.fromJson(doc.data()!);
        
        // --- VERIFICAR RENOVACIÓN MENSUAL AL CARGAR ---
        await checkAndResetMonthlyScans();
        
        notifyListeners();
      } else {
        // Lógica de creación por defecto si el documento no existe...
        final user = _auth.currentUser;
        if (user != null) {
          final now = DateTime.now();
          _currentUser = UserProfile(
            uid: uid,
            username: user.email?.split('@').first ?? 'user',
            firstName: user.displayName ?? '',
            lastName: '',
            email: user.email ?? '',
            birthDateIso: '',
            createdAt: now,
            updatedAt: now,
            lastReset: now, // Iniciamos el ciclo
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AuthController._loadUserProfile failed: $e');
    }
  }

  // --- LÓGICA DE RENOVACIÓN MENSUAL (NO ACUMULABLE) ---
  Future<void> checkAndResetMonthlyScans() async {
    final user = _currentUser;
    // Si no hay usuario, o es PRO (ilimitado) o FREE (no se renueva), salimos.
    if (user == null || user.subscriptionPlan == 'free' || user.subscriptionPlan == 'pro') return;

    final now = DateTime.now();
    final lastReset = user.lastReset ?? user.createdAt;

    // Verificar si han pasado 30 días o más
    if (now.difference(lastReset).inDays >= 30) {
      final int resetValue = user.maxScansByPlan; // 15 para básico, 30 para premium
      
      await _firestore.collection('users').doc(user.uid).update({
        'scansRemaining': resetValue,
        'lastReset': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      _currentUser = user.copyWith(
        scansRemaining: resetValue,
        lastReset: now,
      );
      notifyListeners();
      debugPrint("¡Ciclo mensual cumplido! Escaneos reseteados a $resetValue.");
    }
  }

  // --- DESCONTAR ESCANEO (Compatible con ScanResultPage) ---
  Future<void> useFreeScan() async {
    final user = _currentUser;
    if (user == null || user.subscriptionPlan == 'pro') return;

    if (user.scansRemaining > 0) {
      final newScans = user.scansRemaining - 1;
      final now = DateTime.now();

      try {
        await _firestore.collection('users').doc(user.uid).update({
          'scansRemaining': newScans,
          'updatedAt': Timestamp.fromDate(now),
        });

        _currentUser = user.copyWith(scansRemaining: newScans, updatedAt: now);
        notifyListeners();
      } catch (e) {
        debugPrint('Error al descontar escaneo: $e');
      }
    }
  }

  // --- ACTUALIZAR SUSCRIPCIÓN CON ASIGNACIÓN DE ESCANEOS ---
  Future<void> updateSubscription(String plan) async {
    if (_currentUser == null) return;
    try {
      final now = DateTime.now();
      
      // Creamos un perfil temporal para obtener el máximo de escaneos del nuevo plan
      final tempProfile = _currentUser!.copyWith(subscriptionPlan: plan);
      final int initialScans = tempProfile.maxScansByPlan;

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'subscriptionPlan': plan,
        'scansRemaining': initialScans,
        'lastReset': Timestamp.fromDate(now), // El ciclo de 30 días inicia hoy
        'updatedAt': Timestamp.fromDate(now),
      });

      _currentUser = tempProfile.copyWith(
        scansRemaining:
