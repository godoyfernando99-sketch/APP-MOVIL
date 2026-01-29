import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyView {
  const CurrencyView({required this.code, required this.symbol, required this.usdToCurrency});
  final String code;
  final String symbol;
  final double usdToCurrency;

  String formatUsd(double usd, Locale locale) {
    final value = usd * usdToCurrency;
    final formatter = NumberFormat.currency(locale: locale.toLanguageTag(), name: code, symbol: symbol);
    return formatter.format(value);
  }
}

class AppStrings {
  static const supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
    Locale('it'),
    Locale('th'),
    Locale('fr'),
    Locale('sk'),
    Locale('ru'),
    Locale('de'),
    Locale('lv'),
  ];

  static const supportedLocaleCodes = <String>{'es', 'en', 'it', 'th', 'fr', 'sk', 'ru', 'de', 'lv'};

  static String languageLabel(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'it':
        return 'Italiano';
      case 'th':
        return 'แบบไทย';
      case 'fr':
        return 'Français';
      case 'sk':
        return 'Slovák';
      case 'ru':
        return 'Русский';
      case 'de':
        return 'Deutsch';
      case 'lv':
        return 'Latviešu';
      default:
        return code;
    }
  }

  /// Static conversion rates (approx). You can later fetch real-time rates.
  static CurrencyView currencyForLocale(String code) {
    switch (code) {
      case 'en':
        return const CurrencyView(code: 'USD', symbol: '\$', usdToCurrency: 1.0);
      case 'es':
        return const CurrencyView(code: 'USD', symbol: '\$', usdToCurrency: 1.0);
      case 'it':
      case 'fr':
      case 'de':
      case 'lv':
      case 'sk':
        return const CurrencyView(code: 'EUR', symbol: '€', usdToCurrency: 0.92);
      case 'ru':
        return const CurrencyView(code: 'RUB', symbol: '₽', usdToCurrency: 92.0);
      case 'th':
        return const CurrencyView(code: 'THB', symbol: '฿', usdToCurrency: 35.0);
      default:
        return const CurrencyView(code: 'USD', symbol: '\$', usdToCurrency: 1.0);
    }
  }

  static Map<String, String> _t(String code) {
    switch (code) {
      case 'en':
        return {
          'login': 'Sign in',
          'register': 'Create account',
          'username': 'Username',
          'password': 'Password',
          'continue': 'Continue',
          'welcome': 'Welcome',
          'mainMenu': 'Main menu',
          'homeAnimals': 'Home animals',
          'farmAnimals': 'Farm animals',
          'logout': 'Log out',
          'history': 'History',
          'subscriptions': 'Subscriptions',
          'diseases': 'Diseases',
          'medications': 'Medications',
          'scanWithChip': 'Scan with microchip',
          'scanWithoutChip': 'Scan without microchip',
          'saveInfo': 'Save information',
        };
      case 'it':
        return {
          'login': 'Accedi',
          'register': 'Crea account',
          'username': 'Nome utente',
          'password': 'Password',
          'continue': 'Continua',
          'welcome': 'Benvenuto',
          'mainMenu': 'Menu principale',
          'homeAnimals': 'Animali domestici',
          'farmAnimals': 'Animali da fattoria',
          'logout': 'Esci',
          'history': 'Cronologia',
          'subscriptions': 'Abbonamenti',
          'diseases': 'Malattie',
          'medications': 'Farmaci',
          'scanWithChip': 'Scansione con microchip',
          'scanWithoutChip': 'Scansione senza microchip',
          'saveInfo': 'Salva informazioni',
        };
      case 'fr':
        return {
          'login': 'Connexion',
          'register': 'Créer un compte',
          'username': "Nom d'utilisateur",
          'password': 'Mot de passe',
          'continue': 'Continuer',
          'welcome': 'Bienvenue',
          'mainMenu': 'Menu principal',
          'homeAnimals': 'Animaux de compagnie',
          'farmAnimals': 'Animaux de ferme',
          'logout': 'Déconnexion',
          'history': 'Historique',
          'subscriptions': 'Abonnements',
          'diseases': 'Maladies',
          'medications': 'Médicaments',
          'scanWithChip': 'Scan avec microchip',
          'scanWithoutChip': 'Scan sans microchip',
          'saveInfo': 'Enregistrer',
        };
      case 'de':
        return {
          'login': 'Anmelden',
          'register': 'Konto erstellen',
          'username': 'Benutzername',
          'password': 'Passwort',
          'continue': 'Weiter',
          'welcome': 'Willkommen',
          'mainMenu': 'Hauptmenü',
          'homeAnimals': 'Haustiere',
          'farmAnimals': 'Nutztiere',
          'logout': 'Abmelden',
          'history': 'Verlauf',
          'subscriptions': 'Abos',
          'diseases': 'Krankheiten',
          'medications': 'Medikamente',
          'scanWithChip': 'Scan mit Mikrochip',
          'scanWithoutChip': 'Scan ohne Mikrochip',
          'saveInfo': 'Speichern',
        };
      case 'ru':
        return {
          'login': 'Войти',
          'register': 'Регистрация',
          'username': 'Имя пользователя',
          'password': 'Пароль',
          'continue': 'Продолжить',
          'welcome': 'Добро пожаловать',
          'mainMenu': 'Главное меню',
          'homeAnimals': 'Домашние животные',
          'farmAnimals': 'Фермерские животные',
          'logout': 'Выйти',
          'history': 'История',
          'subscriptions': 'Подписки',
          'diseases': 'Болезни',
          'medications': 'Лекарства',
          'scanWithChip': 'Скан с микрочипом',
          'scanWithoutChip': 'Скан без микрочипа',
          'saveInfo': 'Сохранить',
        };
      case 'sk':
        return {
          'login': 'Prihlásiť sa',
          'register': 'Registrácia',
          'username': 'Používateľ',
          'password': 'Heslo',
          'continue': 'Pokračovať',
          'welcome': 'Vitajte',
          'mainMenu': 'Hlavné menu',
          'homeAnimals': 'Domáce zvieratá',
          'farmAnimals': 'Farmárske zvieratá',
          'logout': 'Odhlásiť',
          'history': 'História',
          'subscriptions': 'Predplatné',
          'diseases': 'Choroby',
          'medications': 'Lieky',
          'scanWithChip': 'Sken s mikročipom',
          'scanWithoutChip': 'Sken bez mikročipu',
          'saveInfo': 'Uložiť',
        };
      case 'lv':
        return {
          'login': 'Pieteikties',
          'register': 'Reģistrēties',
          'username': 'Lietotājvārds',
          'password': 'Parole',
          'continue': 'Turpināt',
          'welcome': 'Laipni lūdzam',
          'mainMenu': 'Galvenā izvēlne',
          'homeAnimals': 'Mājdzīvnieki',
          'farmAnimals': 'Lauksaimniecības dzīvnieki',
          'logout': 'Izrakstīties',
          'history': 'Vēsture',
          'subscriptions': 'Abonementi',
          'diseases': 'Slimības',
          'medications': 'Zāles',
          'scanWithChip': 'Skenēt ar mikroshēmu',
          'scanWithoutChip': 'Skenēt bez mikroshēmas',
          'saveInfo': 'Saglabāt',
        };
      case 'th':
        return {
          'login': 'เข้าสู่ระบบ',
          'register': 'สมัครสมาชิก',
          'username': 'ชื่อผู้ใช้',
          'password': 'รหัสผ่าน',
          'continue': 'ดำเนินการต่อ',
          'welcome': 'ยินดีต้อนรับ',
          'mainMenu': 'เมนูหลัก',
          'homeAnimals': 'สัตว์เลี้ยง',
          'farmAnimals': 'สัตว์ฟาร์ม',
          'logout': 'ออกจากระบบ',
          'history': 'ประวัติ',
          'subscriptions': 'การสมัครสมาชิก',
          'diseases': 'โรค',
          'medications': 'ยา',
          'scanWithChip': 'สแกนด้วยไมโครชิป',
          'scanWithoutChip': 'สแกนไม่มีไมโครชิป',
          'saveInfo': 'บันทึก',
        };
      case 'es':
      default:
        return {
          'login': 'Iniciar sesión',
          'register': 'Crear cuenta',
          'username': 'Usuario',
          'password': 'Contraseña',
          'continue': 'Continuar',
          'welcome': 'Bienvenido',
          'mainMenu': 'Menú principal',
          'homeAnimals': 'Animales de casa',
          'farmAnimals': 'Animales de granja',
          'logout': 'Cerrar sesión',
          'history': 'Historial',
          'subscriptions': 'Suscripciones',
          'diseases': 'Enfermedades',
          'medications': 'Medicamentos',
          'scanWithChip': 'Escaneo con microchip',
          'scanWithoutChip': 'Escaneo sin microchip',
          'saveInfo': 'Guardar información',
        };
    }
  }

  static String of(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    return _t(code)[key] ?? _t('es')[key] ?? key;
  }
}
