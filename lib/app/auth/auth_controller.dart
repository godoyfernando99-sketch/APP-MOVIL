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

  Future<void> updateSubscription(String plan) async {
    if (_currentUser == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      
      final now = DateTime.now();
      final planId = plan.toLowerCase();

      int scans;
      switch (planId) {
        case 'pro': scans = 9999; break;
        case 'intermediate':
        case 'premium': scans = 30; break;
        case 'basic': scans = 15; break;
        default: scans = 3;
      }

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'subscriptionPlan': planId,
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
        debugPrint('Error al descontar escaneo: $e');
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

  // --- REGISTRO CON VALIDACIÓN DE USERNAME ÚNICO ---
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
      
      String cleanUsername = username.trim().toLowerCase();

      final docUsername = await _firestore
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (docUsername.docs.isNotEmpty) {
        return "Este nombre de usuario ya está en uso.";
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      
      await credential.user!.sendEmailVerification();
      
      final now = DateTime.now();
      final profile = UserProfile(
        uid: credential.user!.uid,
        username: cleanUsername,
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
      await signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGIN QUE BUSCA EL EMAIL POR EL USERNAME ---
  Future<String?> login({required String username, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String input = username.trim().toLowerCase();
      String emailToUse;
      
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: input)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return 'El nombre de usuario no existe.';
      }
      
      emailToUse = query.docs.first.data()['email'] as String;
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse, 
        password: password
      );
      
      if (!credential.user!.emailVerified) {
        await signOut();
        return 'Por favor, verifica tu correo electrónico antes de ingresar.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return 'Contraseña incorrecta.';
      return 'Error de acceso: ${e.message}';
    } catch (e) {
      return 'Error en el servidor.';
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
      if (googleUser == null) return 'Cancelado por el usuario.';
      
      final authDetails = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: authDetails.accessToken,
        idToken: authDetails.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        final now = DateTime.now();
        final profile = UserProfile(
          uid: user.uid,
          username: user.email?.split('@').first ?? 'user_${user.uid.substring(0,5)}',
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

  Future<void> signOut() async {
    try {
      _userSubscription?.cancel();
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