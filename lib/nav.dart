import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanneranimal/openai/screens/animals/animal_detail_page.dart';
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
      final isLoggedIn = user != null && user.emailVerified;
      final isOnAuthPage = state.matchedLocation == AppRoutes.login || 
                          state.matchedLocation == AppRoutes.register;
      
      // Si el usuario está autenticado y verificado, y está en una página de autenticación, redirigir al welcome
      if (isLoggedIn && isOnAuthPage) {
        return AppRoutes.welcome;
      }
      
      // Si el usuario no está autenticado y no está en una página de autenticación, redirigir al login
      if (!isLoggedIn && !isOnAuthPage) {
        return AppRoutes.login;
      }
      
      // En todos los demás casos, permitir la navegación normal
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
      GoRoute(path: AppRoutes.register, name: 'register', pageBuilder: (context, state) => const MaterialPage(child: RegisterPage())),
      GoRoute(path: AppRoutes.welcome, name: 'welcome', pageBuilder: (context, state) => const MaterialPage(child: WelcomePage())),
      GoRoute(path: AppRoutes.menu, name: 'menu', pageBuilder: (context, state) => const NoTransitionPage(child: MainMenuPage())),
      GoRoute(path: AppRoutes.animals, name: 'animals', pageBuilder: (context, state) => const MaterialPage(child: AnimalsPage())),
GoRoute(
  path: '${AppRoutes.animals}/:category', // El :category recibirá 'home' o 'farm'
  name: 'animals', 
  pageBuilder: (context, state) {
    // 1. Extraemos el valor de la URL (home o farm)
    final category = state.pathParameters['category'] ?? 'home'; 
    
    // 2. Se lo pasamos a la pantalla de selección de animales
    return MaterialPage(
      child: AnimalsPage(category: category),
    ); 
  },
),
      GoRoute(
        path: '${AppRoutes.scanCapture}/:animalId/:mode',
        name: 'scanCapture',
        pageBuilder: (context, state) {
          final animalId = state.pathParameters['animalId']!;
          final mode = state.pathParameters['mode']!;
          return MaterialPage(child: ScanCapturePage(animalId: animalId, mode: mode));
        },
      ),
  GoRoute(
  path: AppRoutes.scanResult,
  name: 'scanResult',
  pageBuilder: (context, state) {
    // Si 'extra' es nulo, evitamos que la app se cierre
    final extra = state.extra;
    
    if (extra == null) {
      // Opción A: Redirigir al menú si no hay datos
      return const MaterialPage(child: MainMenuPage());
    }
    
    return MaterialPage(child: ScanResultPage(payload: extra));
  },
),
      GoRoute(path: AppRoutes.history, name: 'history', pageBuilder: (context, state) => const MaterialPage(child: HistoryPage())),
      GoRoute(path: AppRoutes.subscriptions, name: 'subscriptions', pageBuilder: (context, state) => const MaterialPage(child: SubscriptionsPage())),
      GoRoute(path: AppRoutes.diseases, name: 'diseases', pageBuilder: (context, state) => const MaterialPage(child: DiseasesPage())),
      GoRoute(path: AppRoutes.medications, name: 'medications', pageBuilder: (context, state) => const MaterialPage(child: MedicationsPage())),
    ],
  );
}

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String welcome = '/welcome';
  static const String menu = '/menu';
  static const String animals = '/animals';
  static const String animal = '/animal';
  static const String scanCapture = '/scan/capture';
  static const String scanResult = '/scan/result';
  static const String history = '/history';
  static const String subscriptions = '/subscriptions';
  static const String diseases = '/diseases';
  static const String medications = '/medications';
}
