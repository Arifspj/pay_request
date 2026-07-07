# Pay Request

A Flutter mobile app to scan UPI QR codes, create payment requests with optional invoice attachments, and share them via WhatsApp or other apps.

## Features

- **QR Scanning** — Scan any UPI-compatible QR code to auto-fill merchant name and UPI ID
- **Floating Scan Button** — Quick-access QR scanner from the home screen
- **Quick Amount Presets** — Tap predefined amounts (₹50, ₹100, etc.) to instantly set the payment value
- **Payment Requests** — Enter amount, attach invoice image, select contact, and generate UPI payment links
- **Share via WhatsApp** — Direct WhatsApp sharing with formatted UPI payment links, QR code, and invoice attachments
- **Enhanced Category UI** — Select from a grid of standard expense categories with descriptive icons and colors (Bottom Sheet)
- **Global Statistics** — Real-time expense tracking across all requests, visualized with category-wise breakdowns in the sidebar
- **Favorites & Starring** — Save contacts from your device address book and "Star" them for quick access
- **Payment History** — Locally stored request history with status badges (Pending / Shared / Completed)
- **Export History** — Export all payment requests as a text file
- **Dark Mode** — Toggle between light and dark themes with a refined "Deep Blue" palette
- **Default Share App** — Choose preferred sharing channel (WhatsApp, Telegram, Email, or System)

## Screens

| Screen | Description |
| :--- | :--- |
| **Home** | Dashboard with live global stats, sidebar navigation, and quick-scan FAB |
| **Favorites** | Contact management with starring support for quick payment access |
| **Settings** | App preferences, Dark Mode toggle, history export, and about info |
| **Scan QR** | High-performance camera-based UPI QR code scanner |
| **Create Request** | Advanced request composer with category picker, invoice attachment, and contact integration |

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Database:** SQLite (sqflite)
- **QR Scanning:** mobile_scanner
- **Contacts:** flutter_contacts
- **Image Pickup:** image_picker
- **Sharing:** share_plus, url_launcher

## Build

```sh
flutter pub get
flutter run
flutter build apk --release
```

### Troubleshooting Build Failures

If you encounter Gradle file locks or Kotlin daemon errors (especially on Windows with multi-drive setups):

1. **Stop Gradle Daemons:** `.\gradlew --stop` (inside the `android` folder)
2. **Clean Project:** `flutter clean`
3. **Rebuild:** `flutter build apk --release --no-shrink`

Note: The APK is typically generated at `android/app/build/outputs/apk/release/app-release.apk`.
