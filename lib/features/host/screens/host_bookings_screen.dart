import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../driver/screens/booking_details_screen.dart';

class HostBookingsScreen extends StatelessWidget {
  final bool showBackButton;

  const HostBookingsScreen({
    super.key,
    this.showBackButton = true,
  });

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _time(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'checkedin':
      case 'checkedIn':
        return Colors.blue;
      case 'checkedout':
      case 'checkedOut':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.black54;
    }
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'checkedIn') 'checkedInAt': FieldValue.serverTimestamp(),
      if (status == 'checkedOut') 'checkedOutAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _refundBooking(BuildContext context, String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refund Booking?'),
        content: const Text('This will request a refund through Stripe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await StripeService().refundBookingPayment(bookingId: bookingId);

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
        'status': 'refunded',
        'paymentStatus': 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking refunded.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refund failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Host Bookings'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: BookingService().streamHostBookings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!;

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'No host bookings yet.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 110 + MediaQuery.of(context).padding.bottom),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final status = booking.status;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(booking.id)
                    .get(),
                builder: (context, detailSnap) {
                  final data = detailSnap.data?.data() ?? {};

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_parking_rounded),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  booking.spaceName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  status,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _statusColor(status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Driver: ${data['driverEmail'] ?? booking.driverId}'),
                          Text('Plate: ${booking.licensePlate}'),
                          Text('Start: ${_time(data['startTime'])}'),
                          Text('End: ${_time(data['endTime'])}'),
                          Text(
                            'Paid: ${_money(booking.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingDetailsScreen(
                                      bookingId: booking.id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.visibility_rounded),
                                label: const Text('View'),
                              ),
                              OutlinedButton.icon(
                                onPressed: status == 'checkedIn'
                                    ? null
                                    : () => _updateStatus(booking.id, 'checkedIn'),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Check In'),
                              ),
                              OutlinedButton.icon(
                                onPressed: status == 'checkedIn'
                                    ? () => _updateStatus(booking.id, 'checkedOut')
                                    : null,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Check Out'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _refundBooking(context, booking.id),
                                icon: const Icon(Icons.currency_exchange_rounded),
                                label: const Text('Refund'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await StripeService().sendBookingReminder(bookingId: booking.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Reminder sent.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.notifications_active_rounded),
                                label: const Text('Reminder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}



