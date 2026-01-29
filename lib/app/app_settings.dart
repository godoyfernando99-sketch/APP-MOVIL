import 'package:flutter/material.dart';

import 'package:scanneranimal/app/storage/local_db.dart';
import 'package:scanneranimal/l10n/app_strings.dart';

class AppSettings extends ChangeNotifier {
  AppSettings(this._db);

  final LocalDb _db;

  Locale _locale = const Locale('es');
  Locale get locale => _locale;

  Future<void> init() async {
    final code = await _db.getLocaleCode();
    if (code != null && AppStrings.supportedLocaleCodes.contains(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocaleCode(String code) async {
    if (!AppStrings.supportedLocaleCodes.contains(code)) return;
    _locale = Locale(code);
    notifyListeners();
    await _db.setLocaleCode(code);
  }

  CurrencyView get currency => AppStrings.currencyForLocale(_locale.languageCode);
}
