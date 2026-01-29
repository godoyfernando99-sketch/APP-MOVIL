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
      // Para web, necesitamos pasar el clientId explícitamente
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
        // Si el documento no existe, crear un perfil básico para permitir que la app funcione
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
      // En caso de error de permisos, crear un perfil temporal para que la app funcione
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

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Send email verification
      await credential.user!.sendEmailVerification();

      // Create user profile in Firestore
      final now = DateTime.now();
      final profile = UserProfile(
        uid: uid,
        username: username.toLowerCase(),
        firstName: firstName,
        lastName: lastName,
        email: email,
        birthDateIso: birthDateIso,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('users').doc(uid).set(profile.toJson());
      
      // Cerrar sesión para que el usuario deba iniciar sesión después de verificar su correo
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthController.register FirebaseAuthException: $e');
      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        return 'El correo electrónico ya está en uso.';
      } else if (e.code == 'invalid-email') {
        return 'El correo electrónico no es válido.';
      }
      return 'No se pudo registrar. Intenta nuevamente.';
    } catch (e) {
      debugPrint('AuthController.register failed: $e');
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
      
      // Intentar buscar usuario por username en Firestore (solo si el username no es un email)
      if (!username.contains('@')) {
        try {
          final usernameQuery = await _firestore.collection('users').where('username', isEqualTo: username.toLowerCase()).limit(1).get();
          if (usernameQuery.docs.isNotEmpty) {
            email = usernameQuery.docs.first.data()['email'] as String;
          }
        } catch (e) {
          debugPrint('Error buscando usuario en Firestore: $e');
          // Si falla Firestore, continuar sin el email
        }

        // Si no se encontró en Firestore y no es un email, devolver error
        if (email == null) {
          return 'Usuario o contraseña incorrectos.';
        }
      } else {
        // El username es un email
        email = username;
      }

      // Sign in with email and password
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Verificar si el correo está verificado
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        return 'Debes verificar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada.';
      }
      
      // Cargar perfil del usuario
      await _loadUserProfile(credential.user!.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthController.login FirebaseAuthException: $e');
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Usuario o contraseña incorrectos.';
      }
      return 'No se pudo iniciar sesión.';
    } catch (e) {
      debugPrint('AuthController.login failed: $e');
      return 'No se pudo iniciar sesión.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return 'Inicio de sesión cancelado.';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken ?? '',
        idToken: googleAuth.idToken ?? '',
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Check if user profile exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create new user profile
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
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthController.signInWithGoogle FirebaseAuthException: $e');
      return 'No se pudo iniciar sesión con Google. Intenta nuevamente.';
    } catch (e) {
      debugPrint('AuthController.signInWithGoogle failed: $e');
      return 'No se pudo iniciar sesión con Google. Intenta nuevamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthController.resetPassword FirebaseAuthException: $e');
      if (e.code == 'user-not-found') {
        return 'No se encontró una cuenta con este correo electrónico.';
      } else if (e.code == 'invalid-email') {
        return 'El correo electrónico no es válido.';
      }
      return 'No se pudo enviar el correo de restablecimiento.';
    } catch (e) {
      debugPrint('AuthController.resetPassword failed: $e');
      return 'No se pudo enviar el correo de restablecimiento.';
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
