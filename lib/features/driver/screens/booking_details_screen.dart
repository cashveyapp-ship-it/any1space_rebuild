import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../../core/services/booking_service.dart';
import 'qr_pass_screen.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _card(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('This will cancel this parking booking.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm != true) return;

    await BookingService().cancelBooking(bookingId);

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Booking Details'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('bookings').doc(bookingId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data();

          if (data == null) {
            return const Center(child: Text('Booking not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                data['spaceName'] ?? 'Booking',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(data['spaceAddress'] ?? ''),
              const SizedBox(height: 18),

              _card('License Plate', data['licensePlate'] ?? '', Icons.directions_car_rounded),
              _card('Status', data['status'] ?? 'pending', Icons.info_rounded),
              _card('Payment', data['paymentStatus'] ?? 'pending', Icons.payment_rounded),
              _card('Start Time', _formatTime(data['startTime']), Icons.play_circle_rounded),
              _card('End Time', _formatTime(data['endTime']), Icons.stop_circle_rounded),
              _card('Amount', _money(data['amount']), Icons.attach_money_rounded),

              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelBooking(context),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancel Booking'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrPassScreen(bookingId: bookingId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const FittedBox(child: Text('View QR Pass')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}




