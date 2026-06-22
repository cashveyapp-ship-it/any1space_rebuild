import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/widgets/apple_back_button.dart';

class QrPassScreen extends StatelessWidget {
  final String bookingId;

  const QrPassScreen({
    super.key,
    required this.bookingId,
  });

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final qrValue = 'ANY1SPACE_BOOKING:$bookingId';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('QR Parking Pass'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('bookings').doc(bookingId).get(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          return Center(
            child: Card(
              margin: const EdgeInsets.all(22),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrValue,
                      version: QrVersions.auto,
                      size: 220,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Any1Space QR Pass',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    if (data == null)
                      Text(bookingId)
                    else ...[
                      Text(
                        data['spaceName'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text('Plate: ${data['licensePlate'] ?? ''}'),
                      Text('Status: ${data['status'] ?? ''}'),
                      Text('Start: ${_formatTime(data['startTime'])}'),
                      Text('End: ${_formatTime(data['endTime'])}'),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

