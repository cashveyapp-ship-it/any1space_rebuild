import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';

class AdminRevenueScreen extends StatelessWidget {
  final bool showBackButton;

  const AdminRevenueScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookings() {
    return FirebaseFirestore.instance.collection('bookings').snapshots();
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
            child: Icon(icon, color: const Color(0xFF0B1F3A)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Admin Revenue'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _bookings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final gross = _sum(docs);
          final platformFee = gross * 0.20;
          final hostNet = gross - platformFee;

          return ListView(
            padding: const EdgeInsets.all(22),
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
                      'Platform Revenue',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${platformFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'From ${docs.length} total bookings',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _metric('Gross Revenue', '\$${gross.toStringAsFixed(2)}', Icons.attach_money_rounded),
              const SizedBox(height: 12),
              _metric('Platform Fee 20%', '\$${platformFee.toStringAsFixed(2)}', Icons.percent_rounded),
              const SizedBox(height: 12),
              _metric('Host Net Payout', '\$${hostNet.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded),
              const SizedBox(height: 12),
              _metric('Total Bookings', docs.length.toString(), Icons.receipt_long_rounded),
            ],
          );
        },
      ),
    );
  }
}

