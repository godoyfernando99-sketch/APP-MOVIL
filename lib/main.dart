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
import 'package:scanneranimal/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar el Servicio de Notificaciones Profesional
  // Configura canales de Emergencia, Dosis e Inyecciones
  await NotificationService.initialize();

  try {
    // Inicialización de Firebase para IA y Sincronización
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
      _requestNotificationPermissions(); // Permisos con AJUSTE FINO para alertas críticas
    });
  }

  // --- LÓGICA DE CALIFICACIÓN (PLAY STORE) ---
  Future<void> _checkReviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadyRated = prefs.getBool('already_rated') ?? false;

    if (!alreadyRated) {
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted) return;

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
            "Tu calificación nos ayuda a seguir salvando animales. ¡Danos 5 estrellas!",
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
                await prefs.setBool('already_rated', true);
                if (await _inAppReview.isAvailable()) {
                  _inAppReview.requestReview();
                } else {
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

  // --- AJUSTE FINO: PERMISOS PARA ALERTAS DE 3 DÍAS Y DOSIS ---
  void _requestNotificationPermissions() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        // Solicitar permiso de notificaciones estándar
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      
      // REQUISITO: Permisos críticos para evitar retrasos por ahorro de batería
      // Garantiza que la vibración SOS y las alarmas de 3 días sean EXACTAS
      await AwesomeNotifications().checkPermissionList(
        channelKey: 'alerts_channel',
        permissions: [
          NotificationPermission.PreciseAlarms, // Alarmas exactas para dosis
          NotificationPermission.Vibration,      // Vibración para tumores/heridas
          NotificationPermission.CriticalAlert,  // Notificación audible en emergencias
        ],
      );
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