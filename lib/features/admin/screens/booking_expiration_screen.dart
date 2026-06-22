import 'package:flutter/material.dart';
import '../../../core/services/booking_expiration_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class BookingExpirationScreen extends StatefulWidget {
  final bool showBackButton;

  const BookingExpirationScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<BookingExpirationScreen> createState() => _BookingExpirationScreenState();
}

class _BookingExpirationScreenState extends State<BookingExpirationScreen> {
  bool _running = false;
  String _message = 'Run this before production testing to clean expired bookings.';

  Future<void> _run() async {
    setState(() {
      _running = true;
      _message = 'Checking bookings...';
    });

    try {
      final count = await BookingExpirationService().expireOldBookings();

      setState(() {
        _message = 'Expired $count booking(s).';
      });
    } catch (e) {
      setState(() {
        _message = 'Expiration failed: $e';
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Expire Bookings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer_off_rounded),
                title: const Text('Expired Booking Cleanup'),
                subtitle: Text(_message),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _running ? null : _run,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_running ? 'Running...' : 'Run Expiration Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
