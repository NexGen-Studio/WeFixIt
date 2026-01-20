import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  bool _isInitialized = false;
  
  // Cache Keys für Offline-Unterstützung
  static const String _cacheKeyIsPro = 'cache_is_pro';
  static const String _cacheKeyCostsUnlock = 'cache_costs_unlock';
  static const String _cacheKeyMaintenanceUnlock = 'cache_maintenance_unlock';
  static const String _cacheKeyLastSync = 'cache_last_sync';
  
  // Entitlements
  static const String entitlementPro = 'pro';
  static const String entitlementCostsLifetime = 'costs_lifetime'; // ID aus MVP_PROGRESS
  static const String entitlementMaintenanceLifetime = 'maintenance_lifetime'; // Lifetime Unlock für Wartungen

  // Offering Identifiers
  static const String offeringDefault = 'default';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // RevenueCat Key vom Backend holen (oder Fallback auf Dart-Defines)
    String apiKey = AppConfigService().revenuecatKey;
    
    // Fallback: Aus Dart-Defines laden (für Development/Testing)
    if (apiKey.isEmpty) {
      if (Platform.isAndroid) {
        apiKey = const String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_ANDROID', defaultValue: '');
      } else if (Platform.isIOS) {
        apiKey = const String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_IOS', defaultValue: '');
      }
    }

    if (apiKey.isEmpty) {
      print('⚠️ RevenueCat API Key nicht konfiguriert. Bitte setze REVENUECAT_PUBLIC_SDK_KEY_ANDROID/IOS in den Dart-Defines oder Supabase Secrets.');
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
             _checkEntitlement(customerInfo, entitlementCostsLifetime) ||
             _checkEntitlement(customerInfo, entitlementMaintenanceLifetime);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Error purchasing package: $e');
      }
      return false;
    }
  }

  /// Status prüfen mit Offline-Cache
  Future<bool> isProUser() async {
    // ZUERST: Supabase is_pro prüfen (Debug/Test Override)
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('is_pro')
            .eq('id', userId)
            .maybeSingle();
        
        if (response != null && response['is_pro'] == true) {
          print('✅ Pro status override from Supabase: TRUE');
          await _cacheProStatus(true); // Cache für Offline
          return true;
        }
      }
    } catch (e) {
      print('⚠️ Error checking Supabase is_pro (offline?): $e');
      // Bei Fehler (offline): Aus Cache laden
      return await _getCachedProStatus();
    }

    // DANN: RevenueCat prüfen (Standard)
    if (!_isInitialized) {
      // Offline? Aus Cache laden
      return await _getCachedProStatus();
    }
    
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = _checkEntitlement(customerInfo, entitlementPro);
      await _cacheProStatus(isPro); // Cache aktualisieren
      return isPro;
    } catch (e) {
      print('⚠️ RevenueCat offline: Loading from cache');
      return await _getCachedProStatus();
    }
  }
  
  /// Alias für isProUser() - für bessere API-Benennung
  Future<bool> isPro() async {
    return await isProUser();
  }
  
  /// Kosten-Modul Freischaltung prüfen (Lifetime oder Pro) mit Offline-Cache
  Future<bool> hasCostsUnlock() async {
    // ZUERST: Supabase is_pro prüfen (Debug/Test Override)
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('is_pro')
            .eq('id', userId)
            .maybeSingle();
        
        if (response != null && response['is_pro'] == true) {
          await _cacheCostsUnlock(true);
          return true; // Pro = alle Features freigeschaltet
        }
      }
    } catch (e) {
      print('⚠️ Error checking Supabase is_pro (offline?): $e');
      return await _getCachedCostsUnlock();
    }

    // DANN: RevenueCat prüfen
    if (!_isInitialized) return await _getCachedCostsUnlock();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasUnlock = _checkEntitlement(customerInfo, entitlementPro) || 
                        _checkEntitlement(customerInfo, entitlementCostsLifetime);
      await _cacheCostsUnlock(hasUnlock);
      return hasUnlock;
    } catch (e) {
      print('⚠️ RevenueCat offline: Loading costs unlock from cache');
      return await _getCachedCostsUnlock();
    }
  }
  
  /// Wartungs-Modul Freischaltung prüfen (Lifetime oder Pro) mit Offline-Cache
  Future<bool> hasMaintenanceUnlock() async {
    // ZUERST: Supabase is_pro prüfen (Debug/Test Override)
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('is_pro')
            .eq('id', userId)
            .maybeSingle();
        
        if (response != null && response['is_pro'] == true) {
          await _cacheMaintenanceUnlock(true);
          return true; // Pro = alle Features freigeschaltet
        }
      }
    } catch (e) {
      print('⚠️ Error checking Supabase is_pro (offline?): $e');
      return await _getCachedMaintenanceUnlock();
    }

    // DANN: RevenueCat prüfen
    if (!_isInitialized) return await _getCachedMaintenanceUnlock();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasUnlock = _checkEntitlement(customerInfo, entitlementPro) || 
                        _checkEntitlement(customerInfo, entitlementMaintenanceLifetime);
      await _cacheMaintenanceUnlock(hasUnlock);
      return hasUnlock;
    } catch (e) {
      print('⚠️ RevenueCat offline: Loading maintenance unlock from cache');
      return await _getCachedMaintenanceUnlock();
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
  
  // ========== OFFLINE CACHE HELPERS ==========
  
  Future<void> _cacheProStatus(bool isPro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKeyIsPro, isPro);
      await prefs.setInt(_cacheKeyLastSync, DateTime.now().millisecondsSinceEpoch);
      print('💾 Cached Pro status: $isPro');
    } catch (e) {
      print('⚠️ Failed to cache Pro status: $e');
    }
  }
  
  Future<bool> _getCachedProStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool(_cacheKeyIsPro) ?? false;
      print('📦 Loaded Pro status from cache: $cached');
      return cached;
    } catch (e) {
      print('⚠️ Failed to load cached Pro status: $e');
      return false;
    }
  }
  
  Future<void> _cacheCostsUnlock(bool hasUnlock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKeyCostsUnlock, hasUnlock);
    } catch (e) {
      print('⚠️ Failed to cache costs unlock: $e');
    }
  }
  
  Future<bool> _getCachedCostsUnlock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cacheKeyCostsUnlock) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _cacheMaintenanceUnlock(bool hasUnlock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKeyMaintenanceUnlock, hasUnlock);
    } catch (e) {
      print('⚠️ Failed to cache maintenance unlock: $e');
    }
  }
  
  Future<bool> _getCachedMaintenanceUnlock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cacheKeyMaintenanceUnlock) ?? false;
    } catch (e) {
      return false;
    }
  }
}
