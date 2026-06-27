import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_request.dart';

class ShareService {
  static String buildUpiUri(PaymentRequest request) {
    final pa = request.upiId;
    final pn = Uri.encodeComponent(request.merchantName);
    final tn = Uri.encodeComponent('Pay Request');
    if (request.amount > 0) {
      final am = request.amount.toStringAsFixed(2);
      return 'upi://pay?pa=$pa&pn=$pn&am=$am&tn=$tn&cu=INR';
    }
    return 'upi://pay?pa=$pa&pn=$pn&tn=$tn';
  }

  static String buildWhatsAppMessage(PaymentRequest request) {
    final sb = StringBuffer();
    sb.writeln('🔔 *Payment Request* 🔔');
    sb.writeln('');
    sb.writeln('🏪 Merchant: ${request.merchantName}');
    if (request.amount > 0) {
      sb.writeln('💵 Amount: \u{20B9}${request.amount.toStringAsFixed(0)}');
    }
    sb.writeln('🆔 UPI ID: *${request.upiId}*');
    return sb.toString();
  }

  static Future<File?> generateQrCodeFile(PaymentRequest request) async {
    try {
      final upiUri = buildUpiUri(request);
      final qrCode = QrCode.fromData(
        data: upiUri,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );
      final qrImage = QrImage(qrCode);

      const padding = 20;
      const size = 600;
      final moduleCount = qrImage.moduleCount;
      final moduleSize = (size - padding * 2) / moduleCount;

      final image = img.Image(width: size, height: size, numChannels: 3);
      image.clear(img.ColorRgb8(255, 255, 255));

      final black = img.ColorRgb8(0, 0, 0);
      for (int row = 0; row < moduleCount; row++) {
        for (int col = 0; col < moduleCount; col++) {
          if (qrImage.isDark(row, col)) {
            final x1 = padding + (col * moduleSize).round();
            final y1 = padding + (row * moduleSize).round();
            final x2 = padding + ((col + 1) * moduleSize).round() - 1;
            final y2 = padding + ((row + 1) * moduleSize).round() - 1;
            img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: black);
          }
        }
      }

      final pngBytes = img.encodePng(image);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/upi_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  static Future<void> shareOnWhatsApp(PaymentRequest request) async {
    final message = buildWhatsAppMessage(request);
    final mobile = request.contactNumber ?? '';

    if (mobile.isNotEmpty) {
      final cleaned = mobile.replaceAll(RegExp(r'[^\d+]'), '');
      final qrFile = await generateQrCodeFile(request);

      if (qrFile != null) {
        try {
          const channel = MethodChannel('com.payrequest/share');
          await channel.invokeMethod('shareToWhatsApp', {
            'phone': cleaned,
            'text': message,
            'imagePath': qrFile.path,
          });
          return;
        } catch (_) {
          // Platform channel failed, fall through
        }
      }

      final waUrl = 'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(waUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // No contact or no QR: system share sheet
    final qrFile = await generateQrCodeFile(request);
    if (qrFile != null) {
      try {
        await Share.shareXFiles(
          [XFile(qrFile.path)],
          text: message,
          subject: 'Pay Request - ${request.merchantName}',
        );
        return;
      } catch (e) {
        // Fallback if QR generation fails
      }
    }

    try {
      await Share.share(
        message,
        subject: 'Pay Request - ${request.merchantName}',
      );
    } on PlatformException {
      rethrow;
    }
  }
}
