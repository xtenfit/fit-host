import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_item.dart';
import '../widgets/user_food_form_sheet.dart';
import 'quantity_entry_screen.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _errorMessage;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    try {
      _controller.stop();
    } catch (_) {}

    await _lookupBarcode(rawValue.trim());
  }

  Future<void> _lookupBarcode(String barcode) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final foodRepo = ref.read(foodRepositoryProvider);
      final food = await foodRepo.getFoodByBarcode(barcode);

      if (!mounted) return;

      if (food != null) {
        // Found either locally or in OpenFoodFacts
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => QuantityEntryScreen(food: food),
          ),
        );

        if (result == true && mounted) {
          context.pop(true);
        } else if (mounted) {
          _resumeScanning();
        }
      } else {
        // Not found
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Couldn\'t reach OpenFoodFacts. Check your connection.';
      });
    }
  }

  void _resumeScanning() {
    setState(() {
      _isProcessing = false;
      _hasScanned = false;
      _errorMessage = null;
    });
    try {
      _controller.start();
    } catch (_) {}
  }

  Future<void> _showNotFoundDialog(String barcode) async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Product Not Found'),
          content: Text(
            'We couldn\'t find a product with barcode $barcode.\nWould you like to add it manually?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add Manually'),
            ),
          ],
        );
      },
    );

    if (shouldAdd == true && mounted) {
      final newFood = await showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => UserFoodFormSheet(initialBarcode: barcode),
      );

      if (newFood != null && mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => QuantityEntryScreen(food: newFood),
          ),
        );
        if (result == true && mounted) {
          context.pop(true);
          return;
        }
      }
    }

    if (mounted) {
      _resumeScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? AppColors.limeGreen : Colors.white,
            ),
            tooltip: 'Toggle Flashlight',
            onPressed: () async {
              try {
                await _controller.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeDetected,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Camera Access Required',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please grant camera permissions to scan barcodes on food products.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.limeGreen,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            _controller.start();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Camera'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Scanning Reticle Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BarcodeOverlayPainter(),
              ),
            ),
          ),

          // Instructions at Top
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.limeGreen),
                    SizedBox(width: 8),
                    Text(
                      'Align barcode within the green frame',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Processing / Loading Overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.limeGreen),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Looking up product...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Error Toast
          if (_errorMessage != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _resumeScanning,
                      child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarcodeOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final scanRectWidth = width * 0.75;
    final scanRectHeight = scanRectWidth * 0.65;
    final left = (width - scanRectWidth) / 2;
    final top = (height - scanRectHeight) / 2 - 30;
    final scanRect = Rect.fromLTWH(left, top, scanRectWidth, scanRectHeight);

    // Dark semi-transparent background around scan rect
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Green corner borders
    final borderPaint = Paint()
      ..color = AppColors.limeGreen
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const r = 16.0;

    // Top-left
    final tlPath = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: const Radius.circular(r))
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(tlPath, borderPaint);

    // Top-right
    final trPath = Path()
      ..moveTo(left + scanRectWidth - cornerLength, top)
      ..lineTo(left + scanRectWidth - r, top)
      ..arcToPoint(Offset(left + scanRectWidth, top + r), radius: const Radius.circular(r))
      ..lineTo(left + scanRectWidth, top + cornerLength);
    canvas.drawPath(trPath, borderPaint);

    // Bottom-left
    final blPath = Path()
      ..moveTo(left, top + scanRectHeight - cornerLength)
      ..lineTo(left, top + scanRectHeight - r)
      ..arcToPoint(Offset(left + r, top + scanRectHeight), radius: const Radius.circular(r))
      ..lineTo(left + cornerLength, top + scanRectHeight);
    canvas.drawPath(blPath, borderPaint);

    // Bottom-right
    final brPath = Path()
      ..moveTo(left + scanRectWidth - cornerLength, top + scanRectHeight)
      ..lineTo(left + scanRectWidth - r, top + scanRectHeight)
      ..arcToPoint(Offset(left + scanRectWidth, top + scanRectHeight - r), radius: const Radius.circular(r))
      ..lineTo(left + scanRectWidth, top + scanRectHeight - cornerLength);
    canvas.drawPath(brPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
