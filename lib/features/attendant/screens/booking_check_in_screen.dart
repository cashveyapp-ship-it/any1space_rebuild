import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/check_in_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class BookingCheckInScreen extends StatefulWidget {
  final String bookingId;

  const BookingCheckInScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingCheckInScreen> createState() => _BookingCheckInScreenState();
}

class _BookingCheckInScreenState extends State<BookingCheckInScreen> {
  bool _saving = false;

  Future<void> _checkIn() async {
    setState(() => _saving = true);

    try {
      await CheckInService().checkIn(widget.bookingId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle checked in.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _saving = true);

    try {
      await CheckInService().checkOut(widget.bookingId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle checked out.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _time(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _row(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value.isEmpty ? 'Not set' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 760;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Verify Booking'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .doc(widget.bookingId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            if (!snapshot.data!.exists) {
              return const Center(child: Text('Booking not found.'));
            }

            final data = snapshot.data!.data() ?? {};
            final status = (data['status'] ?? '').toString();

            return ListView(
              padding: EdgeInsets.fromLTRB(18, compact ? 14 : 22, 18, 28),
              children: [
                Text(
                  data['spaceName'] ?? 'Booking',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 24 : 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking ID: ${widget.bookingId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 12 : 22),
                _row('License Plate', data['licensePlate'] ?? '', Icons.directions_car_rounded),
                _row('Space Number', data['spaceNumber'] ?? 'Not assigned', Icons.local_parking_rounded),
                _row('Status', status, Icons.info_rounded),
                _row('Payment', data['paymentStatus'] ?? '', Icons.payment_rounded),
                _row('Start Time', _time(data['startTime']), Icons.play_circle_rounded),
                _row('End Time', _time(data['endTime']), Icons.stop_circle_rounded),
                _row('Checked In', _time(data['checkedInAt']), Icons.login_rounded),
                _row('Checked Out', _time(data['checkedOutAt']), Icons.logout_rounded),
                SizedBox(height: compact ? 12 : 22),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _saving || status == 'checkedIn' || status == 'checkedOut'
                        ? null
                        : _checkIn,
                    icon: const Icon(Icons.login_rounded),
                    label: Text(_saving ? 'Saving...' : 'Check In Vehicle'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _saving || status != 'checkedIn'
                        ? null
                        : _checkOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Check Out Vehicle'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

