import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:in_app_review/in_app_review.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:awesome_notifications/awesome_notifications.dart'; 

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

  // 1. Inicializar Motor de Notificaciones (Alertas de 3 días, Parto y Medicinas)
  AwesomeNotifications().initialize(
    null, 
    [
      NotificationChannel(
        channelKey: 'alerts_channel',
        channelName: 'Alertas Veterinarias',
        channelDescription: 'Notificaciones de seguimiento, parto y medicación',
        defaultColor: const Color(0xFF9D50BB),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        criticalAlerts: true,
      )
    ],
    debug: true
  );

  try {
    // Inicialización compatible con Firebase 3.0.0
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

    // Verificaciones automáticas al iniciar la App
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkForUpdate();           // Actualizaciones de Google Play
      await _checkReviewStatus();        // Diálogo de Calificación Inteligente
      _requestNotificationPermissions(); // Permisos para recordatorios de salud
    });
  }

  // --- LÓGICA DE CALIFICACIÓN (PLAY STORE) CON MEMORIA ---
  Future<void> _checkReviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadyRated = prefs.getBool('already_rated') ?? false;

    if (!alreadyRated) {
      // Espera de 6 segundos para que cargue el menú primero
      await Future.delayed(const Duration(seconds: 6));
      if (!mounted) return;

      // Usamos el contexto del Router para mostrar el diálogo de forma segura
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 30),
              SizedBox(width: 10),
              Text("¿Te ayuda la App?", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            "Tu calificación nos ayuda a seguir salvando animales. ¡Danos 5 estrellas en Play Store!",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("LUEGO", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // Guardamos permanentemente que ya calificó
                await prefs.setBool('already_rated', true);
                
                if (await _inAppReview.isAvailable()) {
                  _inAppReview.requestReview();
                } else {
                  // Fallback: Abre la tienda directamente si el diálogo nativo falla
                  _inAppReview.openStoreListing();
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text("CALIFICAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  // --- ACTUALIZACIONES IN-APP ---
  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('⚠️ InAppUpdate info: $e');
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
            routerConfig: AppRouter.router, // Configuración de lib/nav.dart
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