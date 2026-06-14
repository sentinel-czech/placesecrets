# Building the PlaceSecrets mobile app

This document covers the configuration the app needs to build and run, and the
exact build commands. Code/config in this repo is ready; the items marked
**(human-supplied)** require credentials/assets that must not live in git.

## 1. Environment / Supabase config (required)

Config is injected at build time via `--dart-define-from-file`. Templates live in
`dart_defines/`:

- `dart_defines/dev.json` — local Supabase (`http://127.0.0.1:54321`).
- `dart_defines/prod.json` — **(human-supplied)** replace the placeholders with the
  real production `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the anon key is
  publishable and protected by RLS, so it may live in the prod build).
  `GOOGLE_IOS_CLIENT_ID` is only needed once Google OAuth is wired (see roadmap).

`lib/core/constants/env.dart` calls `Env.assertConfigured()` at startup and throws
a clear error if these are missing — so a misbuilt binary fails fast with an
actionable message instead of a cryptic Supabase error.

### Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen

# Run / build with the chosen environment file:
flutter run            --dart-define-from-file=dart_defines/dev.json
flutter build apk      --release --dart-define-from-file=dart_defines/prod.json
flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json
flutter build ios      --release --dart-define-from-file=dart_defines/prod.json
```

## 2. Firebase / push notifications (optional but recommended)

Firebase powers FCM push. **Startup is resilient**: if Firebase config is absent
(`bootstrapFirebase()` in `lib/core/services/firebase_bootstrap.dart` catches the
failure), the app still runs — push features simply stay disabled. Local
notifications (geofence alerts) work without Firebase.

To enable push **(human-supplied)**:

1. Create a Firebase project, add Android app `cz.tuma.placesecrets` and an iOS app
   with the matching bundle id.
2. Run `flutterfire configure` (generates `lib/firebase_options.dart`), or drop the
   files manually:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Apply the Google Services Gradle plugin (only after the json exists, otherwise
   the Android build fails): add `id("com.google.gms.google-services")` to
   `android/app/build.gradle.kts` plugins and the classpath in `android/build.gradle.kts`.

These files are intentionally **not** committed.

## 3. App icon

`assets/icons/app_icon.png` is a **placeholder** (brand-green pin). Replace it with
the final 1024×1024 brand icon, then regenerate platform icons:

```bash
dart run flutter_launcher_icons
```

The config (`flutter_launcher_icons:` in `pubspec.yaml`) already removes the alpha
channel for iOS (App Store requirement) and flattens onto the brand color.

## 4. Android release signing **(human-supplied)**

Release builds use an upload keystore configured out-of-repo:

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore ~/placesecrets-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` → `android/key.properties` (gitignored) and
   fill in the passwords / alias / absolute `storeFile` path.

When `android/key.properties` is present the release build is signed with the
upload key; otherwise it falls back to the debug key so `flutter run --release`
still works locally. (`android/app/build.gradle.kts`.)

## 5. Deep links

The custom scheme `placesecrets://` works out of the box (Android intent-filter +
iOS `CFBundleURLTypes`). For verified **https** links (`https://placesecrets.app/...`)
the domain must host association files **(human-supplied, server-side)**:

- Android App Links: `https://placesecrets.app/.well-known/assetlinks.json` with the
  app's `package_name` and the release signing SHA-256 fingerprint.
- iOS Universal Links: add the *Associated Domains* entitlement
  (`applinks:placesecrets.app`) and host
  `https://placesecrets.app/.well-known/apple-app-site-association`.

Without these, https links still open the app's website; the custom scheme keeps
purchase callbacks working regardless.

## 6. OAuth (Google / Apple) **(human-supplied config)**

The app calls `signInWithOAuth` with redirect `placesecrets://login-callback`
(handled automatically by supabase_flutter). To make it work:

1. Enable the Google and Apple providers in the Supabase dashboard (Authentication
   → Providers) with their client IDs/secrets.
2. Add `placesecrets://login-callback` to the Supabase **Redirect URLs** allowlist.
3. Apple: requires an Apple Developer "Sign in with Apple" service id; iOS App
   Store mandates Apple sign-in if any other social login is offered.

Without this config the buttons surface a provider error; email/password is unaffected.

## 7. Verification gates

```bash
flutter analyze
flutter test
```

Note: a real device/emulator is required to validate runtime flows (geofencing,
FCM delivery, deep-link callbacks, payments) — these cannot be verified from
`flutter test` alone.
