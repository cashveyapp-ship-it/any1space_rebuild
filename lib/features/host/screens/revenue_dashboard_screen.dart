import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';

class RevenueDashboardScreen extends StatelessWidget {
  final bool showBackButton;

  const RevenueDashboardScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('hostId', isEqualTo: uid)
        .snapshots();
  }

  double _sum(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double total = 0;
    for (final doc in docs) {
      final data = doc.data();
      if ((data['paymentStatus'] ?? '') == 'refunded') continue;
      total += ((data['amount'] ?? 0) as num).toDouble();
    }
    return total;
  }

  bool _isAfter(dynamic ts, DateTime cutoff) {
    if (ts is! Timestamp) return false;
    return ts.toDate().isAfter(cutoff);
  }

  Widget _metric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEAF1FF),
            child: Icon(icon, color: Color(0xFF0B1F3A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = now.subtract(const Duration(days: 7));
    final month = DateTime(now.year, now.month, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Revenue Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _bookings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final todayDocs = docs.where((d) => _isAfter(d.data()['createdAt'], today)).toList();
          final weekDocs = docs.where((d) => _isAfter(d.data()['createdAt'], week)).toList();
          final monthDocs = docs.where((d) => _isAfter(d.data()['createdAt'], month)).toList();

          final gross = _sum(docs);
          final fee = gross * 0.20;
          final net = gross - fee;

          return ListView(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 120 + MediaQuery.of(context).padding.bottom),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F3A),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Host Net',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${net.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${docs.length} total bookings',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _metric('Today Revenue', '\$${_sum(todayDocs).toStringAsFixed(2)}', Icons.today_rounded),
              const SizedBox(height: 12),
              _metric('Last 7 Days', '\$${_sum(weekDocs).toStringAsFixed(2)}', Icons.calendar_view_week_rounded),
              const SizedBox(height: 12),
              _metric('This Month', '\$${_sum(monthDocs).toStringAsFixed(2)}', Icons.calendar_month_rounded),
              const SizedBox(height: 12),
              _metric('Gross Revenue', '\$${gross.toStringAsFixed(2)}', Icons.attach_money_rounded),
              const SizedBox(height: 12),
              _metric('Any1Space Fee 20%', '\$${fee.toStringAsFixed(2)}', Icons.percent_rounded),
              const SizedBox(height: 12),
              _metric('Total Bookings', docs.length.toString(), Icons.receipt_long_rounded),
            ],
          );
        },
      ),
    );
  }
}


