import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Asegúrate de que esta ruta sea correcta según tu estructura
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
  bool get isLoggedIn => _auth.currentUser != null && (_auth.currentUser?.emailVerified ?? false);
  
  // Getter corregido para mayor seguridad en la comparación
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

  void _initGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '71382402825-95402b132c675faf79f5d8.apps.googleusercontent.com' : null,
      scopes: ['email'],
    );
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
        // Solo reseteamos si no es un plan ilimitado
        if (!isPro) {
          await checkAndResetMonthlyScans();
        }
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Error en el Stream de usuario: $e'));
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

  Future<void> checkAndResetMonthlyScans() async {
    final user = _currentUser;
    if (user == null || isPro) return; // PROs no necesitan reset de límites

    final now = DateTime.now();
    final lastReset = user.lastReset ?? user.createdAt;

    if (now.difference(lastReset).inDays >= 30) {
      final int resetValue = user.maxScansByPlan;
      
      await _firestore.collection('users').doc(user.uid).update({
        'monthlyScans': resetValue, // Sincronizado con el nombre del campo en UserProfile
        'lastReset': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    }
  }

  Future<void> useFreeScan() async {
    final user = _currentUser;
    // Si no hay usuario o es PRO, no descontamos nada
    if (user == null || isPro) return;

    if (user.scansRemaining > 0) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'monthlyScans': user.scansRemaining - 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e) {
        debugPrint('Error al descontar escaneo: $e');
      }
    }
  }

  Future<void> updateSubscription(String plan) async {
    if (_currentUser == null) return;
    try {
      final now = DateTime.now();
      // Usamos el copyWith corregido
      final tempProfile = _currentUser!.copyWith(subscriptionPlan: plan);
      final int initialScans = tempProfile.maxScansByPlan;

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'subscriptionPlan': plan.toLowerCase(),
        'monthlyScans': initialScans,
        'lastReset': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      debugPrint('AuthController.updateSubscription failed: $e');
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
        scansRemaining: 3, // Ahora el constructor lo acepta
      );

      await _firestore.collection('users').doc(profile.uid).set(profile.toJson());
      await _auth.signOut();
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

      String? email = username.trim();
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
        await _auth.signOut();
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

  Future<void> logout() async {
    _userSubscription?.cancel();
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
