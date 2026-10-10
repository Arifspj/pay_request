# AGENTS.md

## Project
Flutter UPI payment request app (`pay_request`). It builds a Paytm-style "Scan & Pay"
standee QR image (Canvas-rendered) and shares it to WhatsApp.

## Build & Release workflow — ALWAYS follow in this order
1. **Version pump** before producing any new APK:
   - `android/app/build.gradle.kts`: increment `versionCode`, bump `versionName`.
   - `pubspec.yaml`: set `version:` to `<versionName>+<versionCode>` so they stay in sync.
2. **Verify**: run `flutter analyze`; fix anything this project introduced (pre-existing
   deprecation info in `create_request_screen.dart` may remain).
3. **Commit & push**: `git add .`, commit with a concise message matching repo style,
   then `git push origin main`.
4. **Build APK** only when the user asks: run `flutter build apk --release`.
   Fresh APK: `build\app\outputs\flutter-apk\app-release.apk` (gitignored).
   Never point the user to stale copies under `android\app\build\...`.

## Notes
- `android/build.gradle.kts` must keep the root-project buildDir redirection
  (`../../build`) so `flutter build apk` finds its outputs.
- QR image generation lives in `lib/services/share_service.dart` (`generateQrCodeFile`).
  It renders via `dart:ui` Canvas + `PictureRecorder`, then writes a PNG to the temp dir.
  A regression test exists at `test/qr_generation_test.dart`.
- Never commit `android/key.jks`, `android/key.properties`, `local.properties`, or
  `app_icon*.png` (already gitignored).