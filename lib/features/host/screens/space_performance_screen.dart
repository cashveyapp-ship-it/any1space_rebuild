import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/space_model.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'manage_space_screen.dart';

class SpacePerformanceScreen extends StatelessWidget {
  final SpaceModel space;

  const SpacePerformanceScreen({
    super.key,
    required this.space,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookings() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('spaceId', isEqualTo: space.id)
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

  Widget _metric(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occupied = space.totalSpaces - space.availableSpaces;
    final occupancy = space.totalSpaces == 0
        ? 0
        : ((occupied / space.totalSpaces) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Lot Performance'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _bookings(),
        builder: (context, snapshot) {
          final bookings = snapshot.data?.docs ?? [];
          final revenue = _sum(bookings);

          return ListView(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 110 + MediaQuery.of(context).padding.bottom),
            children: [
              Text(
                space.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(space.address),
              const SizedBox(height: 18),
              _metric('Total Bookings', bookings.length.toString(), Icons.receipt_long_rounded),
              _metric('Revenue', '\$${revenue.toStringAsFixed(2)}', Icons.attach_money_rounded),
              _metric('Available Spaces', '${space.availableSpaces}/${space.totalSpaces}', Icons.local_parking_rounded),
              _metric('Occupancy', '$occupancy%', Icons.pie_chart_rounded),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageSpaceScreen(space: space),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Manage This Space'),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Recent Bookings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...bookings.take(10).map((doc) {
                final data = doc.data();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car_rounded),
                    title: Text(data['licensePlate'] ?? 'Vehicle'),
                    subtitle: Text('Status: ${data['status'] ?? ''}'),
                    trailing: Text(
                      '\$${((data['amount'] ?? 0) as num).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

