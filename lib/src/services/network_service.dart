import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider für Internet-Status
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

/// Stream Provider für Live-Connectivity Status
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.read(networkServiceProvider).connectivityStream;
});

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  
  /// Live-Stream für Internet-Verbindungsstatus
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      // Connectivity != Internet! Muss tatsächlich testen
      return await hasInternetConnection();
    });
  }
  
  /// Prüft ob eine aktive Internet-Verbindung besteht
  /// Testet durch Lookup zu einem zuverlässigen Host
  Future<bool> hasInternetConnection() async {
    try {
      // Zuerst Connectivity prüfen
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Dann tatsächliche Internet-Verbindung testen
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Wartet auf Internet-Verbindung mit Timeout
  /// Gibt true zurück wenn Internet verfügbar, false bei Timeout
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 7),
    Duration checkInterval = const Duration(milliseconds: 500),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (await hasInternetConnection()) {
        return true;
      }
      await Future.delayed(checkInterval);
    }
    
    return false;
  }
  
  /// Führt eine Aktion mit Internet-Check aus
  /// Zeigt automatisch Dialog bei fehlender Verbindung
  Future<T?> executeWithInternetCheck<T>({
    required Future<T> Function() action,
    String? errorMessage,
  }) async {
    if (!await hasInternetConnection()) {
      // Kein Internet - Error wird vom Caller behandelt
      throw NoInternetException(
        message: errorMessage ?? 'Diese Funktion benötigt eine Internetverbindung',
      );
    }
    
    try {
      return await action();
    } on SocketException catch (_) {
      throw NoInternetException(
        message: 'Internetverbindung unterbrochen',
      );
    } on HttpException catch (_) {
      throw NoInternetException(
        message: 'Keine Verbindung zum Server möglich',
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Custom Exception für fehlende Internet-Verbindung
class NoInternetException implements Exception {
  final String message;
  
  NoInternetException({
    this.message = 'Keine Internetverbindung',
  });
  
  @override
  String toString() => message;
}
