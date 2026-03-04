import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importaciones de pantallas - Asegúrate de que los nombres de archivo sean correctos
import 'package:scanneranimal/openai/screens/animals/animals_page.dart';
import 'package:scanneranimal/openai/screens/auth/login_page.dart';
import 'package:scanneranimal/openai/screens/auth/register_page.dart';
import 'package:scanneranimal/openai/screens/history/history_page.dart';
import 'package:scanneranimal/openai/screens/info/diseases_page.dart';
import 'package:scanneranimal/openai/screens/info/medications_page.dart';
import 'package:scanneranimal/openai/screens/menu/main_menu_page.dart';
import 'package:scanneranimal/openai/screens/scan/scan_capture_page.dart';
import 'package:scanneranimal/openai/screens/scan/scan_result_page.dart';
import 'package:scanneranimal/openai/screens/subscriptions/subscriptions_page.dart';
import 'package:scanneranimal/openai/screens/welcome/welcome_page.dart';
import 'package:scanneranimal/openai/screens/support/vip_support_page.dart';

// Importar el modelo para que ScanResult sea reconocido
import 'package:scanneranimal/app/history/scan_models.dart';

// 1. Mover el Notifier arriba para que AppRouter lo vea correctamente
class AuthStateNotifier extends ChangeNotifier {
  StreamSubscription<User?>? _subscription;

  AuthStateNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppRouter {
  // 2. Inicialización estática corregida
  static final AuthStateNotifier _authNotifier = AuthStateNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null; 
      final isOnAuthPage = state.matchedLocation == AppRoutes.login || 
                          state.matchedLocation == AppRoutes.register;

      if (isLoggedIn && isOnAuthPage) return AppRoutes.welcome;
      if (!isLoggedIn && !isOnAuthPage) return AppRoutes.login;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
      GoRoute(path: AppRoutes.register, name: 'register', pageBuilder: (context, state) => const MaterialPage(child: RegisterPage())),
      GoRoute(path: AppRoutes.welcome, name: 'welcome', pageBuilder: (context, state) => const MaterialPage(child: WelcomePage())),
      GoRoute(path: AppRoutes.menu, name: 'menu', pageBuilder: (context, state) => const NoTransitionPage(child: MainMenuPage())),

      GoRoute(
        path: '${AppRoutes.animals}/:category', 
        name: 'animals', 
        pageBuilder: (context, state) {
          final category = state.pathParameters['category'] ?? 'home'; 
          return MaterialPage(child: AnimalsPage(category: category)); 
        },
      ),

      // Usamos la ruta simplificada que MainMenu espera
      GoRoute(
        path: AppRoutes.scanCapture, 
        name: 'scanCapture',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
          final String animalId = extra?['animalId'] ?? 'generic';
          final String mode = extra?['mode'] ?? 'visual';
          return MaterialPage(child: ScanCapturePage(animalId: animalId, mode: mode));
        },
      ),

      GoRoute(
        path: AppRoutes.scanResult,
        name: 'scanResult',
        pageBuilder: (context, state) {
          final payload = state.extra;
          if (payload is! ScanResult) {
            return const NoTransitionPage(child: MainMenuPage());
          }
          return MaterialPage(child: ScanResultPage(payload: payload));
        },
      ),

      GoRoute(path: AppRoutes.history, name: 'history', pageBuilder: (context, state) => const MaterialPage(child: HistoryPage())),
      GoRoute(path: AppRoutes.subscriptions, name: 'subscriptions', pageBuilder: (context, state) => const MaterialPage(child: SubscriptionsPage())),
      GoRoute(path: AppRoutes.diseases, name: 'diseases', pageBuilder: (context, state) => const MaterialPage(child: DiseasesPage())),
      GoRoute(path: AppRoutes.medications, name: 'medications', pageBuilder: (context, state) => const MaterialPage(child: MedicationsPage())),
      GoRoute(path: AppRoutes.support, name: 'support', pageBuilder: (context, state) => const MaterialPage(child: VipSupportPage())),

      GoRoute(
        path: AppRoutes.profile, 
        name: 'profile', 
        pageBuilder: (context, state) => MaterialPage(
          child: Scaffold(
            appBar: AppBar(title: const Text('Mi Perfil'), backgroundColor: Colors.green),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(FirebaseAuth.instance.currentUser?.email ?? 'Usuario no identificado'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String welcome = '/welcome';
  static const String menu = '/menu';
  static const String animals = '/animals';
  static const String scanCapture = '/scan-capture'; 
  static const String scanResult = '/scan-result';
  static const String history = '/history';
  static const String subscriptions = '/subscriptions';
  static const String diseases = '/diseases';
  static const String medications = '/medications';
  static const String profile = '/profile';
  static const String support = '/support';
  
  // Alias para compatibilidad con MainMenuPage
  static const String capture = scanCapture; 
}