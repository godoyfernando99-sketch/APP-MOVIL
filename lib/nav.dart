import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importaciones de pantallas
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

// IMPORTANTE: Importar el modelo para que GoRouter reconozca el tipo en 'extra'
import 'package:scanneranimal/app/history/scan_models.dart';

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
  static final _authNotifier = AuthStateNotifier();
  
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      // Verifica si el usuario existe (puedes quitar user.emailVerified si quieres permitir acceso sin verificar)
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

      GoRoute(
        path: '${AppRoutes.scanCapture}/:animalId/:mode',
        name: 'scanCapture',
        pageBuilder: (context, state) {
          final animalId = state.pathParameters['animalId'] ?? '';
          final mode = state.pathParameters['mode'] ?? 'nochip';
          return MaterialPage(child: ScanCapturePage(animalId: animalId, mode: mode));
        },
      ),

      GoRoute(
        path: AppRoutes.scanResult,
        name: 'scanResult',
        pageBuilder: (context, state) {
          // Si el payload es un ScanResult, lo pasamos, si no, volvemos al menú
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
  static const String scanCapture = '/scan/capture';
  static const String scanResult = '/scan/result';
  static const String history = '/history';
  static const String subscriptions = '/subscriptions';
  static const String diseases = '/diseases';
  static const String medications = '/medications';
  static const String profile = '/profile';
}
