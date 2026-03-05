import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:in_app_update/in_app_update.dart';

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

  try {
    // Inicialización de Firebase con opciones multiplataforma
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
    // Verificación de actualizaciones críticas de la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    // Solo disponible en Android (Google Play)
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('⚠️ InAppUpdate no disponible o error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Capa de persistencia local
        Provider<LocalDb>(create: (_) => LocalDb()),
        
        // 2. Ajustes globales (Idioma, Tema, etc.)
        ChangeNotifierProxyProvider<LocalDb, AppSettings>(
          create: (_) => AppSettings(LocalDb()),
          update: (_, localDb, previous) => previous ?? AppSettings(localDb)..init(),
        ),
        
        // 3. Controlador de Autenticación (Core del sistema)
        ChangeNotifierProvider(create: (_) => AuthController()..init()),
        
        // 4. Controlador de Historial (Gestiona los escaneos de la IA)
        // Se inicializa después de Auth para estar listo al loguear
        ChangeNotifierProvider(create: (_) => HistoryController()..init()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Scanner Animal',
            debugShowCheckedModeBanner: false,
            
            // Aplicamos los temas personalizados que definimos en theme.dart
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system, // Cambia según la preferencia del dispositivo
            
            // Configuración del Router (lib/nav.dart)
            routerConfig: AppRouter.router,
            
            // Soporte de idiomas para etiquetas dinámicas
            locale: settings.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              // Asegúrate de que AppStrings.delegate esté aquí si usas .arb files
            ],
          );
        },
      ),
    );
  }
}