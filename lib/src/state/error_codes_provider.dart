import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/obd_error_code.dart';

/// Provider für persistente Fehlercode-Speicherung
class ErrorCodesNotifier extends StateNotifier<List<RawObdCode>> {
  ErrorCodesNotifier() : super([]);

  /// Speichere neue Fehlercodes (überschreibt alte)
  void setCodes(List<RawObdCode> codes) {
    state = codes;
  }

  /// Entferne einen einzelnen Code
  void removeCode(String code) {
    state = state.where((c) => c.code != code).toList();
  }

  /// Lösche alle Codes
  void clearAll() {
    state = [];
  }

  /// Prüfe ob Codes vorhanden sind
  bool get hasCodes => state.isNotEmpty;

  /// Anzahl der Codes
  int get count => state.length;
}

final errorCodesProvider = StateNotifierProvider<ErrorCodesNotifier, List<RawObdCode>>((ref) {
  return ErrorCodesNotifier();
});
