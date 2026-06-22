import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'booking_details_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  final bool showBackButton;

  const MyBookingsScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('driverId', isEqualTo: uid)
        .snapshots();
  }

  bool _isHistory(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();

    if (status == 'cancelled' ||
        status == 'checkedout' ||
        status == 'checkedOut'.toLowerCase() ||
        status == 'refunded' ||
        status == 'expired') {
      return true;
    }

    final endTime = data['endTime'];
    if (endTime is Timestamp) {
      return endTime.toDate().isBefore(DateTime.now());
    }

    return false;
  }

  Future<void> _archive(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).set({
      'hiddenByDriver': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _time(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _list(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool history,
  }) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          history ? 'No booking history yet.' : 'No active bookings yet.',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    history
                        ? Icons.history_rounded
                        : Icons.qr_code_rounded,
                  ),
                  title: Text(
                    data['spaceName'] ?? 'Booking',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Plate: ${data['licensePlate'] ?? ''}\n'
                    'Status: ${data['status'] ?? ''} • Payment: ${data['paymentStatus'] ?? ''}\n'
                    'End: ${_time(data['endTime'])}\n'
                    'Amount: ${_money(data['amount'])}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsScreen(bookingId: doc.id),
                    ),
                  ),
                ),
                if (history)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _archive(doc.id),
                      icon: const Icon(Icons.archive_rounded),
                      label: const Text('Archive'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: showBackButton ? const AppleBackButton() : null,
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _bookings(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              return data['hiddenByDriver'] != true;
            }).toList();

            final active = all.where((doc) => !_isHistory(doc.data())).toList();
            final history = all.where((doc) => _isHistory(doc.data())).toList();

            return TabBarView(
              children: [
                _list(context, active, history: false),
                _list(context, history, history: true),
              ],
            );
          },
        ),
      ),
    );
  }
}
