import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class LicensePlateSearchScreen extends StatefulWidget {
  final bool showBackButton;

  const LicensePlateSearchScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<LicensePlateSearchScreen> createState() => _LicensePlateSearchScreenState();
}

class _LicensePlateSearchScreenState extends State<LicensePlateSearchScreen> {
  final _plate = TextEditingController();
  bool _loading = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final plate = _plate.text.trim().toUpperCase();
    if (plate.isEmpty) return;

    setState(() => _loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('licensePlate', isEqualTo: plate)
        .get();

    setState(() {
      _results = snap.docs;
      _loading = false;
    });
  }

  Future<void> _checkIn(String id) async {
    await BookingService().checkIn(id);
    await _search();
  }

  Future<void> _checkOut(String id) async {
    await BookingService().checkOut(id);
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Plate Search'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'License Plate',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car_rounded),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search_rounded),
              label: Text(_loading ? 'Searching...' : 'Search Plate'),
            ),
          ),
          const SizedBox(height: 22),
          if (_results.isEmpty)
            const Text('No results yet.', textAlign: TextAlign.center),
          ..._results.map((doc) {
            final data = doc.data();
            final status = (data['status'] ?? '').toString();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.local_parking_rounded),
                      title: Text(data['spaceName'] ?? 'Booking'),
                      subtitle: Text(
                        'Plate: ${data['licensePlate'] ?? ''}\nStatus: $status\nPayment: ${data['paymentStatus'] ?? ''}',
                      ),
                      isThreeLine: true,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: status == 'checkedIn' ? null : () => _checkIn(doc.id),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Check In'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: status == 'checkedIn' ? () => _checkOut(doc.id) : null,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Check Out'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
