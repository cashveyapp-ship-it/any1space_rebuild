import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/check_in_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'booking_check_in_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final bool showBackButton;

  const QrScannerScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  Future<void> _handleCode(String? code) async {
    if (_handled || code == null || code.trim().isEmpty) return;

    setState(() => _handled = true);

    try {
      final booking = await CheckInService().getBookingFromQr(code);

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingCheckInScreen(bookingId: booking.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) setState(() => _handled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final scanSize = shortestSide < 390 ? 220.0 : 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Scan QR Pass'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final code = capture.barcodes.isEmpty
                    ? null
                    : capture.barcodes.first.rawValue;
                ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('QR: ')),
);

_handleCode(code);
              },
            ),
            Center(
              child: Container(
                width: scanSize,
                height: scanSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Place the driver QR pass inside the frame.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


