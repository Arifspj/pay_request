# Pay Request

A Flutter mobile app to scan UPI QR codes, create payment requests with optional invoice attachments, and share them via WhatsApp or other apps.

## Features

- **QR Scanning** — Scan any UPI-compatible QR code to auto-fill merchant name and UPI ID
- **Floating Scan Button** — Quick-access QR scanner from the home screen
- **Payment Requests** — Enter amount, attach invoice image, select contact, and generate UPI payment links
- **Share via WhatsApp** — Direct WhatsApp sharing with formatted UPI payment links, QR code, and invoice attachments
- **Smart Category** — Remembers your last used category for faster request creation
- **Sidebar Navigation** — Easy access to all app pages via a sliding drawer
- **Favorites** — Save frequently-used contacts from your device address book for quick access
- **Payment History** — Locally stored request history with status badges (Pending / Shared / Completed)
- **Export History** — Export all payment requests as a text file
- **Dark Mode** — Toggle between light and dark themes (persisted across sessions)
- **Default Share App** — Choose preferred sharing channel (WhatsApp, Telegram, Email, or System)

## Screens

| Screen | Description |
|--------|-------------|
| Home | Dashboard with stats (Total/Paid/Pending), Sidebar navigation, and Scan QR FAB |
| Favorites | Saved contacts from address book with add/remove support |
| Settings | Dark mode toggle, default share app picker, export history, about |
| Scan QR | Camera-based UPI QR code scanner |
| Create Request | Form to compose and share payment requests |

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
