import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pay_request/models/payment_request.dart';
import 'package:pay_request/services/share_service.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateQrCodeFile renders the new standee image', () async {
    PathProviderPlatform.instance = _FakePathProvider();

    final req = PaymentRequest(
      merchantName: 'Sharma General Store',
      upiId: 'paytmqr5hweer@ptys',
      amount: 499,
      contactNumber: '9876543210',
    );

    final file = await ShareService.generateQrCodeFile(req);
    expect(file, isNotNull, reason: 'generateQrCodeFile returned null');

    final bytes = await file!.readAsBytes();
    final w = _be32(bytes, 16);
    final h = _be32(bytes, 20);
    // ignore: avoid_print
    print('IMAGE_PATH=${file.path}');
    // ignore: avoid_print
    print('IMAGE_BYTES=${bytes.length}');
    // ignore: avoid_print
    print('IMAGE_SIZE=${w}x$h');
    expect(w, 1080);
    expect(h, 2160);
  });
}

int _be32(List<int> b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
