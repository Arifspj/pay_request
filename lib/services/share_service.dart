import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (request.category != null && request.category!.isNotEmpty) {
      sb.writeln('📂 Category: ${request.category}');
    }
    if (request.remarks != null && request.remarks!.isNotEmpty) {
      sb.writeln('📝 Remarks: ${request.remarks}');
    }
    sb.writeln('🆔 UPI ID: *${request.upiId}*');
    return sb.toString();
  }

  // ---- Design palette ----
  static const Color _cyan = Color(0xFF00BAF2);
  static const Color _navy = Color(0xFF002970);
  static const Color _deepNavy = Color(0xFF00194A);
  static const Color _lightCyan = Color(0xFFE8F7FD);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _cream = Color(0xFFFFFBF2);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _red = Color(0xFFEF4444);
  static const Color _emerald = Color(0xFF10B981);

  static const double _w = 1080;
  static const double _cardMargin = 60;
  static const double _cardWidth = _w - _cardMargin * 2;
  static const double _cardTop = 90;
  static const double _cardHeight = 1510;
  static const double _totalHeight = 2160;

  static TextPainter _tp(
    String text,
    double size,
    Color color,
    FontWeight weight, {
    TextAlign align = TextAlign.center,
    double letterSpacing = 0,
    double maxWidth = double.infinity,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    );
    tp.layout(maxWidth: maxWidth);
    return tp;
  }

  static void _paintCentered(
    Canvas canvas,
    TextPainter tp,
    double y, {
    double? left,
    double? width,
  }) {
    final l = left ?? _cardMargin;
    final wd = width ?? _cardWidth;
    tp.paint(canvas, Offset(l + (wd - tp.width) / 2, y));
  }

  static Path _heartPath(double cx, double cy, double s) {
    final p = Path();
    p.moveTo(cx, cy + s);
    p.cubicTo(cx - s * 1.4, cy - s * 0.2, cx - s * 0.6, cy - s * 1.1, cx, cy - s * 0.35);
    p.cubicTo(cx + s * 0.6, cy - s * 1.1, cx + s * 1.4, cy - s * 0.2, cx, cy + s);
    p.close();
    return p;
  }

  static Future<ui.Image?> _loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static void _drawImageContain(Canvas canvas, ui.Image image, Rect dst) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    if (iw == 0 || ih == 0) return;
    final scale = (dst.width / iw) < (dst.height / ih)
        ? dst.width / iw
        : dst.height / ih;
    final w = iw * scale;
    final h = ih * scale;
    final dx = dst.left + (dst.width - w) / 2;
    final dy = dst.top + (dst.height - h) / 2;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, ih),
      Rect.fromLTWH(dx, dy, w, h),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  static void _gradientBorder(
    Canvas canvas,
    Rect rect,
    double radius,
    List<Color> colors, {
    double strokeWidth = 10,
  }) {
    final inset = strokeWidth / 2;
    final stops = List<double>.generate(
      colors.length,
      (i) => colors.length <= 1 ? 0.0 : i / (colors.length - 1),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = ui.Gradient.linear(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.bottom),
        colors,
        stops,
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular(radius - inset),
      ),
      paint,
    );
  }

  static Future<File?> generateQrCodeFile(PaymentRequest request) async {
    try {
      final upiUri = buildUpiUri(request);
      final qrCode = QrCode.fromData(
        data: upiUri,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );
      final qrImage = QrImage(qrCode);

      final iconImage = await _loadAssetImage('assets/app_icon.png');
      final upiLogosImage =
          await _loadAssetImage('assets/Pay-Using-Any-UPI-App.png.png');
      final upiLogoIcon = await _loadAssetImage('assets/upi_logo_icon.png');

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final centerX = _w / 2;

      // 1. Background gradient (cyan -> navy)
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, _w, _totalHeight),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(0, _totalHeight),
            [_cyan, _navy, _deepNavy],
            [0.0, 0.55, 1.0],
          ),
      );

      // 2. White standee card with gradient border
      final cardRect = Rect.fromLTWH(_cardMargin, _cardTop, _cardWidth, _cardHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(36)),
        Paint()..color = _white,
      );
      _gradientBorder(canvas, cardRect, 36, const [_cyan, _blue, _navy]);

      // 2b. Abstract corner decorations (modern touch)
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(36)),
      );
      canvas.drawCircle(
        Offset(cardRect.left + 190, cardRect.top + 50),
        190,
        Paint()..color = _cyan.withValues(alpha: 0.12),
      );
      canvas.drawCircle(
        Offset(cardRect.right - 90, cardRect.top - 70),
        150,
        Paint()..color = _blue.withValues(alpha: 0.10),
      );
      canvas.drawCircle(
        Offset(cardRect.left - 90, cardRect.bottom - 40),
        200,
        Paint()..color = _navy.withValues(alpha: 0.07),
      );
      canvas.drawCircle(
        Offset(cardRect.right - 160, cardRect.bottom - 90),
        170,
        Paint()..color = _cyan.withValues(alpha: 0.09),
      );
      canvas.drawCircle(
        Offset(cardRect.right - 30, cardRect.top + 170),
        9,
        Paint()..color = _cyan.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        Offset(cardRect.left - 40, cardRect.top + 260),
        6,
        Paint()..color = _blue.withValues(alpha: 0.14),
      );
      canvas.restore();

      // 3. App icon (zoomed out) + Brand "Pay Request"
      const iconSize = 120.0;
      final iconTop = _cardTop + 46;
      if (iconImage != null) {
        _drawImageContain(
          canvas,
          iconImage,
          Rect.fromLTWH(centerX - iconSize / 2, iconTop, iconSize, iconSize),
        );
      }
      final brandY = iconTop + iconSize + 28;
      final payTp = _tp('Pay', 66, _navy, FontWeight.w800);
      final reqTp = _tp(' Request', 66, _cyan, FontWeight.w800);
      final brandW = payTp.width + reqTp.width;
      var bx = centerX - brandW / 2;
      payTp.paint(canvas, Offset(bx, brandY));
      bx += payTp.width;
      reqTp.paint(canvas, Offset(bx, brandY));

      // 4. "Scan & Pay" label
      final scanTp = _tp('Scan & Pay', 30, _slate600, FontWeight.w600, letterSpacing: 2);
      _paintCentered(canvas, scanTp, brandY + 84);

      // 5. Amount pill
      const pillTop = 424.0;
      const pillH = 172.0;
      final amountLabel = request.amount > 0
          ? '\u{20B9}${request.amount.toStringAsFixed(2)}'
          : 'Enter any amount';
      final amtTp = _tp(amountLabel, request.amount > 0 ? 92 : 64, _navy, FontWeight.w800);
      final pillW = amtTp.width + 140;
      final pillX = centerX - pillW / 2;
      final pillRect = Rect.fromLTWH(pillX, pillTop, pillW, pillH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(pillH / 2)),
        Paint()..color = _lightCyan,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(pillH / 2)),
        Paint()
          ..color = _cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        Offset(pillX + 66, pillTop + pillH / 2),
        13,
        Paint()..color = _emerald,
      );
      amtTp.paint(
        canvas,
        Offset(pillX + (pillW + 48 - amtTp.width) / 2, pillTop + (pillH - amtTp.height) / 2),
      );

      // 6. QR code with quiet zone
      const qrBoxSize = 560.0;
      final qrBoxX = centerX - qrBoxSize / 2;
      const qrBoxY = 610.0;
      final qrBoxRect = Rect.fromLTWH(qrBoxX, qrBoxY, qrBoxSize, qrBoxSize);
      canvas.drawRRect(
        RRect.fromRectAndRadius(qrBoxRect, const Radius.circular(20)),
        Paint()..color = _white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(qrBoxRect, const Radius.circular(20)),
        Paint()
          ..color = _slate200
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      const quiet = 34.0;
      final qrDrawSize = qrBoxSize - quiet * 2;
      final qrDrawX = qrBoxX + quiet;
      final qrDrawY = qrBoxY + quiet;
      final moduleCount = qrImage.moduleCount;
      final moduleSize = qrDrawSize / moduleCount;
      final darkPaint = Paint()..color = _slate900;
      for (int row = 0; row < moduleCount; row++) {
        for (int col = 0; col < moduleCount; col++) {
          if (qrImage.isDark(row, col)) {
            canvas.drawRect(
              Rect.fromLTWH(
                qrDrawX + col * moduleSize,
                qrDrawY + row * moduleSize,
                moduleSize + 0.6,
                moduleSize + 0.6,
              ),
              darkPaint,
            );
          }
        }
      }

      // 7. UPI ID row (with UPI logo icon)
      final upiY = qrBoxY + qrBoxSize + 40;
      final upiTp = _tp('UPI ID:  ${request.upiId}', 34, _slate900,
          FontWeight.w600, maxWidth: _cardWidth - 80);
      const upiIconSize = 44.0;
      const upiIconGap = 16.0;
      final upiRowW =
          (upiLogoIcon != null ? upiIconSize + upiIconGap : 0.0) + upiTp.width;
      var upiRowX = centerX - upiRowW / 2;
      if (upiLogoIcon != null) {
        _drawImageContain(
          canvas,
          upiLogoIcon,
          Rect.fromLTWH(upiRowX, upiY, upiIconSize, upiIconSize),
        );
        upiRowX += upiIconSize + upiIconGap;
      }
      upiTp.paint(
        canvas,
        Offset(upiRowX, upiY + (upiIconSize - upiTp.height) / 2),
      );

      // 8. "Pay using any UPI App" label + logos banner (asset image)
      final logosTag = _tp('Pay using any UPI App', 26, _slate600,
          FontWeight.w600, letterSpacing: 2);
      final logosTop = upiY + (upiLogoIcon != null ? 44.0 : 0.0) + 22;
      _paintCentered(canvas, logosTag, logosTop);
      if (upiLogosImage != null) {
        const logosW = 760.0;
        final logosH = logosW * upiLogosImage.height / upiLogosImage.width;
        _drawImageContain(
          canvas,
          upiLogosImage,
          Rect.fromLTWH(centerX - logosW / 2, logosTop + 44, logosW, logosH),
        );
      }

      // 10. Co-branding banner: "payrequest ❤ UPI"
      final bannerY = _cardTop + _cardHeight + 70;
      final b1 = _tp('payrequest', 58, _white, FontWeight.w800, letterSpacing: -1);
      final b2 = _tp('UPI', 58, _white, FontWeight.w800, letterSpacing: 2);
      final heartW = 70.0;
      final bannerTotal = b1.width + heartW + b2.width + 60;
      var hx = centerX - bannerTotal / 2;
      b1.paint(canvas, Offset(hx, bannerY));
      hx += b1.width + 30;
      canvas.drawPath(_heartPath(hx + heartW / 2, bannerY + 34, 22), Paint()..color = _red);
      hx += heartW + 30;
      b2.paint(canvas, Offset(hx, bannerY));

      // 11. Merchant footer (cream plate)
      const footerTop = 1770.0;
      const footerH = 310.0;
      final footerRect = Rect.fromLTWH(_cardMargin, footerTop, _cardWidth, footerH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(footerRect, const Radius.circular(28)),
        Paint()..color = _cream,
      );
      _gradientBorder(canvas, footerRect, 28, const [_navy, _blue, _cyan]);

      final nameTp = _tp(request.merchantName.toUpperCase(), 54, _slate900, FontWeight.w800,
          letterSpacing: 1, maxWidth: _cardWidth - 80);
      _paintCentered(canvas, nameTp, footerTop + 80);

      final secondLine =
          (request.contactNumber != null && request.contactNumber!.isNotEmpty)
              ? request.contactNumber!
              : request.upiId;
      final phoneTp = _tp(secondLine, 42, _slate600, FontWeight.w700,
          letterSpacing: 1, maxWidth: _cardWidth - 80);
      _paintCentered(canvas, phoneTp, footerTop + 160);

      // Render to PNG
      final picture = recorder.endRecording();
      final image = await picture.toImage(_w.toInt(), _totalHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      iconImage?.dispose();
      upiLogosImage?.dispose();
      upiLogoIcon?.dispose();
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/pay_request_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e, s) {
      debugPrint('generateQrCodeFile ERROR: $e\n$s');
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
          const channel = MethodChannel('pay.request/share');
          await channel.invokeMethod('shareToWhatsApp', {
            'phone': cleaned,
            'text': message,
            'imagePath': qrFile.path,
            'invoicePath': request.invoicePath ?? '',
          });
          return;
        } catch (_) {}
      }

      final waUrl = 'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(waUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final qrFile = await generateQrCodeFile(request);
    if (qrFile != null) {
      await Share.shareXFiles([XFile(qrFile.path)], text: message);
    } else {
      await Share.share(message);
    }
  }
}
