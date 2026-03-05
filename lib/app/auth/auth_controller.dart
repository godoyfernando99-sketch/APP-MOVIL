import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_profile.dart'; 

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  bool get isLoggedIn {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.emailVerified || user.providerData.any((p) => p.providerId == 'google.com');
  }

  bool get isPro => _currentUser?.isPro ?? false;

  AuthController() {
    _initGoogleSignIn();
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _userSubscription?.cancel();
        _currentUser = null;
        notifyListeners();
      } else {
        _listenToUserProfile(user.uid);
      }
    });
  }

  /// MÉTODO: init llamado desde main.dart
  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();
      final user = _auth.currentUser;
      if (user != null) {
        _listenToUserProfile(user.uid);
      }
    } catch (e) {
      debugPrint('AuthController.init failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '71382402825-95402b132c675faf79f5d8.apps.googleusercontent.com' : null,
      scopes: ['email'],
    );
  }

  Future<String?> sendPasswordReset(String email) async {
    if (email.isEmpty) return "Por favor, ingresa tu correo.";
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found': return "No existe un usuario con este correo.";
        default: return e.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToUserProfile(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data() != null) {
        _currentUser = UserProfile.fromJson(doc.data()!);
        if (!isPro) {
          await checkAndResetMonthlyScans();
        }
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Error en el Stream de usuario: $e'));
  }

  /// MÉTODO: updateSubscription para la página de planes
  Future<void> updateSubscription(String plan) async {
    if (_currentUser == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      final now = DateTime.now();

      int scans = (plan.toLowerCase() == 'pro' || plan.toLowerCase() == 'gold') ? 9999 : 3;

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'subscriptionPlan': plan.toLowerCase(),
        'monthlyScans': scans,
        'lastReset': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      debugPrint('Error al actualizar suscripción: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> useFreeScan() async {
    final user = _currentUser;
    if (user == null || isPro) return;
    if (user.scansRemaining > 0) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'monthlyScans': user.scansRemaining - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error al descontar: $e');
      }
    }
  }

  Future<void> checkAndResetMonthlyScans() async {
    final user = _currentUser;
    if (user == null || isPro) return;
    final now = DateTime.now();
    final lastReset = user.lastReset ?? user.createdAt;
    if (now.difference(lastReset).inDays >= 30) {
      await _firestore.collection('users').doc(user.uid).update({
        'monthlyScans': user.maxScansByPlan,
        'lastReset': Timestamp.fromDate(now),
      });
    }
  }

  Future<String?> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String birthDateIso,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      await credential.user!.sendEmailVerification();
      final now = DateTime.now();
      final profile = UserProfile(
        uid: credential.user!.uid,
        username: username.toLowerCase().trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        birthDateIso: birthDateIso,
        createdAt: now,
        updatedAt: now,
        lastReset: now,
        subscriptionPlan: 'free',
        scansRemaining: 3, 
      );
      await _firestore.collection('users').doc(profile.uid).set(profile.toJson());
      await signOut(); // Se usa el nuevo nombre del método
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login({required String username, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();
      String email = username.trim();
      if (!email.contains('@')) {
        final query = await _firestore
            .collection('users')
            .where('username', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (query.docs.isEmpty) return 'Usuario no encontrado.';
        email = query.docs.first.data()['email'] as String;
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      if (!credential.user!.emailVerified) {
        await signOut(); // Se usa el nuevo nombre del método
        return 'Verifica tu correo electrónico.';
      }
      return null;
    } catch (e) {
      return 'Credenciales incorrectas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Cancelado.';
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        final now = DateTime.now();
        final profile = UserProfile(
          uid: user.uid,
          username: user.email?.split('@').first ?? 'user',
          firstName: user.displayName?.split(' ').first ?? '',
          lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: user.email ?? '',
          birthDateIso: '',
          createdAt: now,
          updatedAt: now,
          lastReset: now,
          subscriptionPlan: 'free',
          scansRemaining: 3,
        );
        await _firestore.collection('users').doc(user.uid).set(profile.toJson());
      }
      return null;
    } catch (e) {
      return 'Error con Google: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// CORRECCIÓN: Nombre cambiado de logout a signOut para coincidir con el Router y Menú
  Future<void> signOut() async {
    try {
      _userSubscription?.cancel();
      // Cerramos sesión de Google solo si hubo una sesión activa
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error durante el cierre de sesión: $e');
    } finally {
      _currentUser = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}