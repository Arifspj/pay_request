import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'create_request_screen.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  MobileScannerController? _controller;
  bool _scanning = true;
  bool _cameraDenied = false;
  String? _upiId;
  String? _merchantName;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _controller = MobileScannerController();
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null) return;
      final result = await _controller?.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final barcode = result.barcodes.first;
        if (barcode.rawValue != null && barcode.rawValue!.trim().isNotEmpty) {
          _parseUPI(barcode.rawValue!);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR code found in the image'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) setState(() => _cameraDenied = true);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null || barcode!.rawValue!.trim().isEmpty) return;

    final raw = barcode.rawValue!;
    _parseUPI(raw);
  }

  void _parseUPI(String raw) {
    String? pa;
    String? pn;

    if (raw.startsWith('upi://')) {
      final uri = Uri.parse(raw);
      pa = uri.queryParameters['pa'];
      pn = uri.queryParameters['pn'];
    } else if (raw.contains('@')) {
      pa = raw.trim();
    }

    if (pa != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _scanning = false;
        _upiId = pa;
        _merchantName = pn ?? 'Unknown Merchant';
      });
      _controller?.stop();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreateRequestScreen(
                upiId: _upiId,
                merchantName: _merchantName,
              ),
            ),
          );
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not a valid UPI QR code'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Pick from gallery',
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
          ),
        ],
      ),
      body: SafeArea(
        child: _cameraDenied
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.no_photography,
                          size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Camera permission is required to scan QR codes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => openAppSettings(),
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                        ),
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        if (!_scanning)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    'UPI Detected!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _merchantName ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        Text(
                          'SCAN MERCHANT QR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Position QR code within the frame',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Or pick from gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        if (_upiId != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.store, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Merchant'),
                                    const Spacer(),
                                    Text(
                                      _merchantName ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(Icons.payments, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('UPI'),
                                    const Spacer(),
                                    Text(
                                      _upiId!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
