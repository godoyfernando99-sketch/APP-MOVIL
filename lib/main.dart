import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  runApp(const ScannerAnimalApp());
}

class ScannerAnimalApp extends StatelessWidget {
  const ScannerAnimalApp({super.key});

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
