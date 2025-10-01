import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLocaleProvider = StateProvider<Locale?>((ref) => null);

void setAppLocale(WidgetRef ref, Locale? locale) {
  ref.read(appLocaleProvider.notifier).state = locale;
}
