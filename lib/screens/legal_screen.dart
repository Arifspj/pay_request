import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class LegalContent {
  static const String privacyPolicy = '''
Privacy Policy

Last Updated: October 2023

1. Information We Collect
Pay Request is designed to be privacy-friendly. We do not collect your personal data on our servers. All data, including merchant names, UPI IDs, and payment history, is stored locally on your device.

2. Permissions
- Camera: Required to scan UPI QR codes.
- Storage: Required to save and share invoice images.
- Contacts: Optional, used only if you choose to add a favorite from your contact list.

3. Third-Party Services
We use WhatsApp for sharing payment requests. Your use of WhatsApp is governed by their own privacy policy.

4. Data Security
Since all data is stored locally, the security of your data depends on your device's security. We recommend using screen locks and other security features provided by your mobile OS.

5. Changes to This Policy
We may update our Privacy Policy from time to time. Any changes will be posted on this page with an updated date.
''';

  static const String termsAndConditions = '''
Terms & Conditions

Last Updated: October 2023

1. Acceptance of Terms
By using Pay Request, you agree to these Terms & Conditions. If you do not agree, please do not use the app.

2. Use of the App
Pay Request is a tool to help you generate UPI payment links and share them. We are not a payment processor. All transactions happen through your UPI-enabled apps and the NPCI network.

3. Disclaimer of Warranties
The app is provided "as is" without any warranties. We do not guarantee that the app will be error-free or that the payment links generated will always be accepted by all UPI apps.

4. Limitation of Liability
Pay Request and its developers shall not be liable for any financial losses, failed transactions, or data loss resulting from the use of the app.

5. User Responsibility
You are responsible for ensuring that the UPI ID and amount entered are correct before sharing the request.

6. Modifications
We reserve the right to modify or discontinue the app at any time without notice.
''';
}
