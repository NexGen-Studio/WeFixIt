# wefixit

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Setup (Supabase, Firebase/FCM, RevenueCat)

1. Create Supabase project and set RLS on. Run SQL in `supabase/schema.sql`.
2. Create Firebase project, add Android/iOS apps, download configs:
   - Android: place `google-services.json` under `android/app/`.
   - iOS: add `GoogleService-Info.plist` to Xcode project (Runner).
3. RevenueCat: create products/entitlements with IDs:
   - wefixit_pro_month, wefixit_pro_year
   - wefixit_credits_10
   - wefixit_marketplace_highlight_7d

## Environment Variables

Use `env.example` as template. Option A: `--dart-define-from-file=env.example` (for local test). Option B: create `.env` and reference it.

Required keys:
- SUPABASE_URL, SUPABASE_ANON_KEY
- REVENUECAT_PUBLIC_SDK_KEY_ANDROID, REVENUECAT_PUBLIC_SDK_KEY_IOS
- FCM_SENDER_ID, FIREBASE_ANDROID_APP_ID, FIREBASE_IOS_APP_ID
- AI_BASE_URL (for Edge Functions proxy)

## Build/Run with dart-define

```bash
flutter run \
  --dart-define-from-file=env.example
```

Or specify individually:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=REVENUECAT_PUBLIC_SDK_KEY_ANDROID=... \
  --dart-define=REVENUECAT_PUBLIC_SDK_KEY_IOS=...
```

## Notes
- Ensure Android/iOS permissions for Bluetooth/Location/Camera/Notifications are configured when implementing OBD/Chat.
- Apply schema before first app login to avoid missing tables.