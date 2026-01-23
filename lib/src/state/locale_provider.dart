import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show PlatformDispatcher;

final appLocaleProvider = StateProvider<Locale?>((ref) => null);

String currentLanguageCode = PlatformDispatcher.instance.locale.languageCode;

void setAppLocale(WidgetRef ref, Locale? locale) {
  ref.read(appLocaleProvider.notifier).state = locale;
  currentLanguageCode = locale?.languageCode ?? currentLanguageCode;
  // Speichere Locale für Notifications (Background Tasks)
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString('locale', locale?.languageCode ?? 'de');
  });
}
