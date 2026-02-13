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
        notifyListeners();
      } else {
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
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AuthController._loadUserProfile failed: $e');
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
        );
        notifyListeners();
      }
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
      );

      await _firestore.collection('users').doc(uid).set(profile.toJson());
      
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contraseña es demasiado débil.';
      if (e.code == 'email-already-in-use') return 'El correo electrónico ya está en uso.';
      if (e.code == 'invalid-email') return 'El correo electrónico no es válido.';
      return 'No se pudo registrar: ${e.message}';
    } catch (e) {
      return 'No se pudo registrar. Intenta nuevamente.';
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
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Usuario o contraseña incorrectos.';
      }
      return 'Error al iniciar sesión: ${e.message}';
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
        );
        await _firestore.collection('users').doc(user.uid).set(profile.toJson());
        _currentUser = profile;
      } else {
        _currentUser = UserProfile.fromJson(userDoc.data()!);
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

  // FUNCIÓN CORREGIDA PARA RESTABLECER CONTRASEÑA
  Future<String?> resetPassword({required String email}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Limpieza del email para evitar errores de espacios
      final cleanEmail = email.trim();
      
      if (cleanEmail.isEmpty) return 'Por favor, ingresa tu correo.';

      debugPrint('Solicitando restablecimiento de contraseña para: $cleanEmail');

      await _auth.sendPasswordResetEmail(email: cleanEmail);
      
      debugPrint('Correo de restablecimiento enviado correctamente por Firebase API');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en resetPassword [${e.code}]: ${e.message}');
      if (e.code == 'user-not-found') {
        return 'No existe una cuenta asociada a este correo.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo electrónico no es válido.';
      } else if (e.code == 'too-many-requests') {
        return 'Demasiadas solicitudes. Intenta de nuevo en unos minutos.';
      }
      return 'No se pudo enviar el correo: ${e.message}';
    } catch (e) {
      debugPrint('Error inesperado en resetPassword: $e');
      return 'Ocurrió un error inesperado al intentar enviar el correo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthController.logout failed: $e');
    }
  }

  Future<void> decrementScans() async {
    if (_currentUser == null) return;
    try {
      final newScansRemaining = (_currentUser!.scansRemaining - 1).clamp(0, 999);
      _currentUser = _currentUser!.copyWith(
        scansRemaining: newScansRemaining,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'scansRemaining': newScansRemaining,
        'updatedAt': Timestamp.fromDate(_currentUser!.updatedAt),
      });
    } catch (e) {
      debugPrint('AuthController.decrementScans failed: $e');
    }
  }

  Future<void> updateSubscription(String plan) async {
    if (_currentUser == null) return;
    try {
      _currentUser = _currentUser!.copyWith(
        subscriptionPlan: plan,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'subscriptionPlan': plan,
        'updatedAt': Timestamp.fromDate(_currentUser!.updatedAt),
      });
    } catch (e) {
      debugPrint('AuthController.updateSubscription failed: $e');
    }
  }
}
