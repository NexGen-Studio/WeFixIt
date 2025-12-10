import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  bool _isInitialized = false;
  
  // Entitlements
  static const String entitlementPro = 'pro';
  static const String entitlementCostsLifetime = 'costs_lifetime'; // ID aus MVP_PROGRESS

  // Offering Identifiers
  static const String offeringDefault = 'default';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // RevenueCat Keys aus Environment Variables laden (SICHER!)
    String apiKey = ''; 
    if (Platform.isAndroid) {
      apiKey = const String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_ANDROID', defaultValue: '');
    } else if (Platform.isIOS) {
      apiKey = const String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_IOS', defaultValue: '');
    }

    if (apiKey.isEmpty) {
      print('⚠️ RevenueCat API Key nicht konfiguriert. Bitte setze REVENUECAT_PUBLIC_SDK_KEY_ANDROID/IOS in den Dart-Defines.');
      return; // Abbrechen wenn kein Key vorhanden
    }

    await Purchases.setLogLevel(LogLevel.debug);
    
    PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
    
    // User ID setzen (Supabase ID), damit Käufe synchronisiert werden
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      configuration.appUserID = userId;
    }

    await Purchases.configure(configuration);
    _isInitialized = true;
  }

  /// Aktuelle Offerings abrufen
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      print('⚠️ RevenueCat not initialized - skipping offerings');
      // Versuchen wir nochmal zu initialisieren? Besser nicht automatisch.
      return null;
    }
    
    try {
      print('🔍 Calling Purchases.getOfferings()...');
      final offerings = await Purchases.getOfferings();
      print('✅ Purchases.getOfferings() success: ${offerings.all.length} offerings found');
      return offerings;
    } on PlatformException catch (e) {
      print('❌ Error fetching offerings (PlatformException): ${e.message} | Code: ${e.code} | Details: ${e.details}');
      // Silent fail if RevenueCat not configured (optional feature)
      return null;
    } catch (e) {
      print('❌ Error fetching offerings (General): $e');
      return null;
    }
  }

  /// Paket kaufen
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return _checkEntitlement(customerInfo, entitlementPro) || 
             _checkEntitlement(customerInfo, entitlementCostsLifetime);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Error purchasing package: $e');
      }
      return false;
    }
  }

  /// Status prüfen
  Future<bool> isProUser() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _checkEntitlement(customerInfo, entitlementPro);
    } catch (e) {
      return false;
    }
  }
  
  /// Alias für isProUser() - für bessere API-Benennung
  Future<bool> isPro() async {
    return await isProUser();
  }
  
  /// Kosten-Modul Freischaltung prüfen (Lifetime oder Pro)
  Future<bool> hasCostsUnlock() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _checkEntitlement(customerInfo, entitlementPro) || 
             _checkEntitlement(customerInfo, entitlementCostsLifetime);
    } catch (e) {
      return false;
    }
  }

  bool _checkEntitlement(CustomerInfo customerInfo, String entitlementId) {
    final entitlement = customerInfo.entitlements.all[entitlementId];
    return entitlement != null && entitlement.isActive;
  }
  
  /// Restore Purchases
  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }
}
