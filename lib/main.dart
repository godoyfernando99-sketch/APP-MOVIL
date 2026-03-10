import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; 

import 'package:scanneranimal/app/app_settings.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/storage/local_db.dart';
import 'package:scanneranimal/firebase_options.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/app_services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Notificaciones (Crítico para el seguimiento de 3 días)
  await NotificationService.initialize();

  try {
    // 2. Inicialización de Firebase
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

  @override
  void initState() {
    super.initState();

    // Ejecutar lógica de sistema tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _forceUpdateIfAvailable(); // Forzar actualización v1.0.34
      _requestNotificationPermissions(); 
    });
  }

  // --- ACTUALIZACIÓN FORZADA (IN APP UPDATE) ---
  Future<void> _forceUpdateIfAvailable() async {
    try {
      // Verifica si hay una actualización pendiente en la Play Store
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // performImmediateUpdate bloquea la app con una pantalla de Google Play
        // hasta que el usuario descargue la nueva versión.
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('⚠️ InAppUpdate Info: No hay actualización obligatoria o error: $e');
    }
  }

  // --- PERMISOS DE NOTIFICACIONES (Android 13+ y Emergencias) ---
  void _requestNotificationPermissions() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      
      // Permisos para canales de riesgo/emergencia (Crítico para tu nueva IA)
      await AwesomeNotifications().checkPermissionList(
        channelKey: 'emergency_channel', 
        permissions: [
          NotificationPermission.PreciseAlarms,
          NotificationPermission.Vibration,
          NotificationPermission.CriticalAlert,
          NotificationPermission.Sound,
        ],
      );
    });
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
        // Aquí es donde se manejan los 10 escaneos gratuitos iniciales
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