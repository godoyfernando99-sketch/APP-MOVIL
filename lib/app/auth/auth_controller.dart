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
        scansRemaining: initialScans,
        lastReset: now,
        updatedAt: now,
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('AuthController.updateSubscription failed: $e');
    }
  }

  // --- MÉTODOS DE AUTH (LOGIN, REGISTER, GOOGLE, ETC.) ---

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
      final uid = credential.user!.uid;

      await credential.user!.sendEmailVerification();

      final now = DateTime.now();
      final profile = UserProfile(
        uid: uid,
        username: username.toLowerCase().trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        birthDateIso: birthDateIso,
        createdAt: now,
        updatedAt: now,
        lastReset: now, // Fecha inicial de ciclo
      );

      await _firestore.collection('users').doc(uid).set(profile.toJson());
      
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contraseña es demasiado débil.';
      if (e.code == 'email-already-in-use') return 'El correo electrónico ya está en uso.';
      return 'No se pudo registrar: ${e.message}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login({required String username, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();

      String? email;
      final cleanUsername = username.trim().toLowerCase();
      
      if (!cleanUsername.contains('@')) {
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: cleanUsername)
            .limit(1)
            .get();
            
        if (usernameQuery.docs.isNotEmpty) {
          email = usernameQuery.docs.first.data()['email'] as String;
        }
        if (email == null) return 'Usuario o contraseña incorrectos.';
      } else {
        email = cleanUsername;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        return 'Debes verificar tu correo electrónico antes de iniciar sesión.';
      }
      
      await _loadUserProfile(credential.user!.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Usuario o contraseña incorrectos.';
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
      if (googleUser == null) return 'Inicio de sesión cancelado.';

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
          username: user.email?.split('@').first ?? 'user_${user.uid.substring(0, 8)}',
          firstName: user.displayName?.split(' ').first ?? '',
          lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: user.email ?? '',
          birthDateIso: '',
          createdAt: now,
          updatedAt: now,
          lastReset: now,
        );
        await _firestore.collection('users').doc(user.uid).set(profile.toJson());
        _currentUser = profile;
      } else {
        _currentUser = UserProfile.fromJson(userDoc.data()!);
        await checkAndResetMonthlyScans();
      }
      
      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al conectar con Google.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } catch (e) {
      return 'Error al enviar el correo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
