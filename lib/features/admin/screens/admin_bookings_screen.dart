import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../driver/screens/booking_details_screen.dart';

class AdminBookingsScreen extends StatelessWidget {
  final bool showBackButton;

  const AdminBookingsScreen({
    super.key,
    this.showBackButton = true,
  });

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  Future<void> _setStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('All Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_rounded),
                  title: Text(data['spaceName'] ?? 'Booking'),
                  subtitle: Text(
                    'Driver: ${data['driverEmail'] ?? data['driverId'] ?? ''}\n'
                    'Host: ${data['hostId'] ?? ''}\n'
                    'Plate: ${data['licensePlate'] ?? ''}\n'
                    'Status: ${data['status'] ?? ''} • ${_money(data['amount'])}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsScreen(bookingId: doc.id),
                          ),
                        );
                      } else {
                        _setStatus(doc.id, v);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'view', child: Text('View Details')),
                      PopupMenuItem(value: 'paid', child: Text('Mark Paid')),
                      PopupMenuItem(value: 'checkedIn', child: Text('Checked In')),
                      PopupMenuItem(value: 'checkedOut', child: Text('Checked Out')),
                      PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      PopupMenuItem(value: 'refunded', child: Text('Refunded')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
