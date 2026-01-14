# 📡 Offline-Handling & Internet-Check System

**WeFixIt** hat jetzt ein vollständiges Offline-Handling System implementiert.

---

## ✅ Was wurde implementiert?

### 1. **Internet-Check beim App-Start (Splash Screen)**
- ⏱️ **7 Sekunden Wartezeit**: App wartet max. 7 Sekunden auf Internetverbindung
- 🎨 **Animiertes WiFi-Icon**: Pulsierendes Icon während der Suche
- 🚫 **App startet NICHT ohne Internet**: Zeigt Fehlermeldung + "Erneut versuchen" Button
- ✅ **Nutzerfreundlich**: Klare Statusmeldungen statt technischer Errors

**Implementierung:** `lib/splash_screen.dart`

---

### 2. **Globale Error-Unterdrückung**
Alle Network-Exceptions werden automatisch abgefangen und **NICHT** als roter Error-Screen angezeigt.

**Implementierung:** `lib/main.dart`
```dart
runZonedGuarded(() {
  // App läuft in Error-Zone
  FlutterError.onError = (details) {
    if (ErrorHandler.isNetworkError(details.exception)) {
      print('🌐 Network-Fehler unterdrückt');
      return; // Kein roter Error-Screen!
    }
  };
}, (error, stack) {
  // Async Errors auch abfangen
  if (ErrorHandler.isNetworkError(error)) {
    print('🌐 Async Network-Fehler unterdrückt');
  }
});
```

**Erkannte Error-Types:**
- `SocketException`
- `HttpException`
- `ClientException`
- Supabase "Failed host lookup"
- RevenueCat "Unable to resolve host"

---

### 3. **Internet-Required Dialog Widget**
Schöner, nutzerfreundlicher Dialog statt technischer Fehlermeldungen.

**Design:**
- ❌ WiFi-Off Icon in rotem Kreis
- 📝 Klare Nachricht: "Keine Internetverbindung"
- 🔄 "Erneut versuchen" Button
- ❌ "Abbrechen" Button

**Verwendung:**
```dart
// In jedem Screen:
final hasInternet = await InternetRequiredDialog.show(
  context,
  message: 'Diese Funktion benötigt Internet',
);

if (hasInternet == true) {
  // Aktion ausführen
}
```

**Implementierung:** `lib/src/widgets/internet_required_dialog.dart`

---

### 4. **NetworkService**
Zentrale Service-Klasse für alle Internet-Checks.

**Features:**
- ✅ `hasInternetConnection()`: Testet echte Verbindung (nicht nur WiFi an/aus)
- ⏳ `waitForConnection()`: Wartet max. X Sekunden auf Internet
- 🔄 `connectivityStream`: Live-Updates bei Verbindungsänderungen
- 🛡️ `executeWithInternetCheck()`: Wrapper für async Funktionen

**Verwendung:**
```dart
final networkService = NetworkService();

// Check
if (await networkService.hasInternetConnection()) {
  // Internet verfügbar
}

// Warten
final hasInternet = await networkService.waitForConnection(
  timeout: Duration(seconds: 7),
);

// Mit Auto-Check
try {
  await networkService.executeWithInternetCheck(
    action: () async => await supabase.from('table').select(),
  );
} on NoInternetException catch (e) {
  // Kein Internet
}
```

**Implementierung:** `lib/src/services/network_service.dart`

---

### 5. **ErrorHandler Utility**
Intelligente Error-Erkennung und Handling.

**Features:**
- 🔍 `isNetworkError(error)`: Erkennt alle Network-Fehler
- 📱 `handleError(context, error)`: Zeigt passenden Dialog
- 🚀 `executeWithErrorHandling()`: Wrapper mit Loading + Error-Handling

**Verwendung:**
```dart
// Manuelle Error-Prüfung
try {
  await someNetworkCall();
} catch (e) {
  if (ErrorHandler.isNetworkError(e)) {
    await ErrorHandler.handleError(context, e);
  }
}

// Automatisch mit Wrapper
final result = await ErrorHandler.executeWithErrorHandling(
  context: context,
  action: () async => await supabase.from('table').select(),
  showLoadingIndicator: true,
);
```

**Implementierung:** `lib/src/utils/error_handler.dart`

---

### 6. **Offline-Cache für Pro-Status**
Pro-Status wird mit SharedPreferences gecached, damit Features auch offline freigeschaltet bleiben.

**Features:**
- 💾 Cache beim ersten Online-Login
- 📦 Laden aus Cache wenn offline
- 🔄 Auto-Update bei Online-Verbindung

**Was funktioniert offline:**
- ✅ Pro-Status Prüfung
- ✅ Maintenance-Unlock
- ✅ Costs-Unlock
- ✅ Wartungen anzeigen (wenn vorher geladen)
- ✅ Demo-Modus (OBD2)

**Was NICHT offline funktioniert:**
- ❌ Login/Registration
- ❌ Neue Wartungen speichern
- ❌ AI-Diagnose / Ask Toni
- ❌ RevenueCat Käufe

**Implementierung:** `lib/src/services/purchase_service.dart`

---

## 🧪 Testen

### Test 1: App-Start ohne Internet
```
1. Flugmodus AN
2. App starten
3. ✅ Sollte zeigen: "Diese App benötigt eine Internetverbindung"
4. ✅ Button: "Erneut versuchen"
5. Flugmodus AUS
6. Button klicken
7. ✅ App startet normal
```

### Test 2: Pro-Status offline
```
1. Internet AN → App starten
2. Mit is_pro = TRUE Account einloggen
3. Wartungen öffnen → Kategorien testen
4. Internet AUS → App KOMPLETT schließen
5. App NEU starten (ohne Internet)
6. Wartungen öffnen
7. ✅ Kategorien sollten OHNE Paywall verfügbar sein
```

### Test 3: Funktion ohne Internet
```
1. App mit Internet starten
2. Internet AUS
3. Ask Toni öffnen → Nachricht senden
4. ✅ Sollte freundlichen Dialog zeigen: "Internetverbindung benötigt"
5. NICHT: Roter Error-Screen mit SocketException
```

---

## 📝 Best Practices für neue Features

### ❌ NICHT SO:
```dart
// Rohe Supabase-Calls ohne Error-Handling
final data = await Supabase.instance.client
  .from('table')
  .select();
// → Zeigt hässlichen Error bei Offline!
```

### ✅ SONDERN SO:
```dart
// Option 1: Mit ErrorHandler Wrapper
final data = await context.executeWithErrorHandling(
  action: () async => await Supabase.instance.client
    .from('table')
    .select(),
);

// Option 2: Mit try-catch + ErrorHandler
try {
  final data = await Supabase.instance.client
    .from('table')
    .select();
} catch (e) {
  await context.showError(e);
}

// Option 3: Mit NetworkService
final networkService = NetworkService();
try {
  await networkService.executeWithInternetCheck(
    action: () async => await supabase.from('table').select(),
  );
} on NoInternetException {
  // Kein Internet
}
```

---

## 🔧 Konfiguration

### Splash-Screen Timeout ändern:
`lib/splash_screen.dart` → Zeile 112
```dart
_hasInternet = await _networkService.waitForConnection(
  timeout: const Duration(seconds: 7), // <-- Hier ändern
);
```

### Internet-Check Host ändern:
`lib/src/services/network_service.dart` → Zeile 36
```dart
final result = await InternetAddress.lookup('google.com'); // <-- Hier ändern
```

---

## 📊 Architektur

```
┌─────────────────────────────────────────┐
│         App Start (main.dart)           │
│  ┌──────────────────────────────────┐   │
│  │  runZonedGuarded                 │   │
│  │  → Fängt alle Exceptions ab      │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│       Splash Screen                     │
│  ┌──────────────────────────────────┐   │
│  │  NetworkService.waitFor          │   │
│  │  Connection(7 sec)               │   │
│  │  → Animiertes WiFi-Icon          │   │
│  │  → "Erneut versuchen" bei Fail   │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
                    ↓
         Kein Internet? → App startet NICHT
         Internet OK? → Weiter zu Home
                    ↓
┌─────────────────────────────────────────┐
│         Screens (Home, etc.)            │
│  Bei Network-Calls:                     │
│  ┌──────────────────────────────────┐   │
│  │  ErrorHandler.execute            │   │
│  │  WithErrorHandling()             │   │
│  │  → Zeigt InternetRequiredDialog  │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## 🎯 Ergebnis

### Vorher:
❌ Rote Error-Screens mit Stack Traces  
❌ "ClientException with SocketException..."  
❌ App startet ohne Internet → Crashes überall  
❌ Technische Fehlermeldungen für User  

### Nachher:
✅ Freundliche Dialoge mit Icons  
✅ "Diese App benötigt eine Internetverbindung"  
✅ App wartet auf Internet beim Start  
✅ Pro-Status funktioniert offline  
✅ Keine hässlichen Error-Screens mehr  

---

**Entwickler:** Cascade AI  
**Datum:** 2026-01-12  
**Version:** 1.0.0
