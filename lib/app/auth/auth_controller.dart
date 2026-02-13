El problema principal en tu AuthController es que la carga del perfil del usuario es estática. Es decir, lee los datos de Firebase una vez cuando inicias sesión, pero si luego compras un plan o cambias algo en la base de datos, el código no "se entera" automáticamente a menos que reinicies la app.

He corregido el código implementando un Stream (Escucha en tiempo real). Ahora, en cuanto el campo subscriptionPlan cambie a pro en Firebase, el AuthController lo detectará al instante y desbloqueará el soporte VIP y los conteos.

Aquí tienes el nuevo auth_controller.dart:

Dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scanneranimal/app/auth/user_profile.dart';

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
  
  // Getter útil para la UI
  bool get isPro => _currentUser?.subscriptionPlan == 'pro';

  AuthController() {
    _initGoogleSignIn();
    // Escuchar cambios de autenticación
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

  // --- ESCUCHA EN TIEMPO REAL (CORRECCIÓN CLAVE) ---
  void _listenToUserProfile(String uid) {
    _userSubscription?.cancel(); // Cancelar suscripción previa si existe
    
    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data() != null) {
        _currentUser = UserProfile.fromJson(doc.data()!);
        
        // Verificar reseteo mensual
        await checkAndResetMonthlyScans();
        
        notifyListeners(); // Esto actualiza la UI automáticamente cuando cambias a PRO
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

  // --- LÓGICA DE RENOVACIÓN MENSUAL ---
  Future<void> checkAndResetMonthlyScans() async {
    final user = _currentUser;
    if (user == null || user.subscriptionPlan == 'free' || user.subscriptionPlan == 'pro') return;

    final now = DateTime.now();
    final lastReset = user.lastReset ?? user.createdAt;

    if (now.difference(lastReset).inDays >= 30) {
      final int resetValue = user.maxScansByPlan;
      
      await _firestore.collection('users').doc(user.uid).update({
        'scansRemaining': resetValue,
        'lastReset': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      debugPrint("Ciclo mensual reseteado.");
    }
  }

  // --- DESCONTAR ESCANEO ---
  Future<void> useFreeScan() async {
    final user = _currentUser;
    if (user == null || user.subscriptionPlan == 'pro') return;

    if (user.scansRemaining > 0) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'scansRemaining': user.scansRemaining - 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e) {
        debugPrint('Error al descontar escaneo: $e');
      }
    }
  }

  // --- ACTUALIZAR SUSCRIPCIÓN ---
  Future<void> updateSubscription(String plan) async {
    if (_currentUser == null) return;
    try {
      final now = DateTime.now();
      
      // Calculamos escaneos según el nuevo plan usando un temporal
      final tempProfile = _currentUser!.copyWith(subscriptionPlan: plan);
      final int initialScans = tempProfile.maxScansByPlan;

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'subscriptionPlan': plan,
        'scansRemaining': initialScans,
        'lastReset': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // Nota: notifyListeners() será llamado automáticamente por el Stream (_listenToUserProfile)
    } catch (e) {
      debugPrint('AuthController.updateSubscription failed: $e');
    }
  }

  // --- REGISTRO ---
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
        scansRemaining: 3, // Valor inicial por defecto
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

  // --- LOGIN ---
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

  // --- GOOGLE SIGN IN ---
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
