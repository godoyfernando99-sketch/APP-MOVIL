import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:in_app_review/in_app_review.dart'; // Nuevo
import 'package:shared_preferences/shared_preferences.dart'; // Nuevo
import 'package:awesome_notifications/awesome_notifications.dart'; // Nuevo

import 'package:scanneranimal/app/app_settings.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/storage/local_db.dart';
import 'package:scanneranimal/firebase_options.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Notificaciones (Icono de la campana)
  AwesomeNotifications().initialize(
    null, // Icono por defecto (puedes poner 'resource://drawable/res_app_icon')
    [
      NotificationChannel(
        channelKey: 'alerts_channel',
        channelName: 'Alertas Veterinarias',
        channelDescription: 'Notificaciones de seguimiento, parto y medicación',
        defaultColor: const Color(0xFF9D50BB),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      )
    ],
  );

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('🚨 Firebase initialization failed: $e');
  }

  runApp(const ScannerAnimalApp());
}

class ScannerAnimalApp extends StatefulWidget {
  const ScannerAnimalApp({super.key});

  @override
  State<ScannerAnimalApp> createState() => _ScannerAnimalAppState();
}

class _ScannerAnimalAppState extends State<ScannerAnimalApp> {
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    
    // Verificaciones automáticas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkForUpdate();     // Actualizaciones de Play Store
      await _checkReviewStatus();  // Pedir calificación si no lo ha hecho
      _requestNotificationPermissions(); // Pedir permiso para recordatorios
    });
  }

  // --- LÓGICA DE CALIFICACIÓN (PLAY STORE) ---
  Future<void> _checkReviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadyRated = prefs.getBool('already_rated') ?? false;

    if (!alreadyRated) {
      // Esperamos 5 segundos después de abrir para no ser invasivos
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      showDialog(
        context: Navigator.of(context).overlay!.context, // Contexto global
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("⭐ ¡Tu opinión cuenta!", style: TextStyle(color: Colors.white)),
          content: const Text("¿Te gusta ScannerAnimal? Califícanos para seguir mejorando el cuidado animal.", 
            style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("LUEGO", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                await prefs.setBool('already_rated', true);
                if (await _inAppReview.isAvailable()) {
                  _inAppReview.requestReview();
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text("CALIFICAR"),
            ),
          ],
        ),
      );
    }
  }

  // --- LÓGICA DE NOTIFICACIONES ---
  void _requestNotificationPermissions() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('⚠️ InAppUpdate error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalDb>(create: (_) => LocalDb()),
        ChangeNotifierProxyProvider<LocalDb, AppSettings>(
          create: (_) => AppSettings(LocalDb()),
          update: (_, localDb, previous) => previous ?? AppSettings(localDb)..init(),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()..init()),
        ChangeNotifierProvider(create: (_) => HistoryController()..init()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Scanner Animal',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.router,
            locale: settings.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}