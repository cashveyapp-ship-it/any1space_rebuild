import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderService {
  Future<void> sendBookingReminder({
    required String bookingId,
    required Map<String, dynamic> booking,
  }) async {
    final host = FirebaseAuth.instance.currentUser;
    final driverId = (booking['driverId'] ?? '').toString();

    if (driverId.isEmpty) {
      throw Exception('Driver ID missing on booking.');
    }

    final spaceName = (booking['spaceName'] ?? 'your parking space').toString();
    final plate = (booking['licensePlate'] ?? '').toString();

    final body =
        'Reminder from host: Your Any1Space booking for $spaceName is active. Please check in when you arrive. Plate: $plate';

    final notification = {
      'userId': driverId,
      'driverId': driverId,
      'type': 'bookingReminder',
      'title': 'Booking Reminder',
      'body': body,
      'message': body,
      'bookingId': bookingId,
      'spaceId': booking['spaceId'] ?? '',
      'spaceName': spaceName,
      'hostId': host?.uid ?? booking['hostId'] ?? '',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .collection('notifications')
        .add(notification);

    await FirebaseFirestore.instance.collection('notifications').add(notification);

    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
      'lastReminderAt': FieldValue.serverTimestamp(),
      'lastReminderBy': host?.uid ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
