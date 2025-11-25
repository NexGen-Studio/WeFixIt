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

    // TODO: Keys aus Environment oder Config laden
    // Hier bitte die echten Keys eintragen!
    String apiKey = ''; 
    if (Platform.isAndroid) {
      apiKey = 'goog_...'; // Android Key
    } else if (Platform.isIOS) {
      apiKey = 'appl_...'; // iOS Key
    }

    if (apiKey.isEmpty || apiKey.startsWith('goog_...')) {
      print('⚠️ RevenueCat API Key nicht konfiguriert.');
      return;
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
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      print('Error fetching offerings: $e');
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
