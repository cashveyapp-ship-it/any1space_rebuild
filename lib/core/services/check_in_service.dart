import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckInService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String bookingIdFromQr(String raw) {
    final value = raw.trim();

    if (value.startsWith('ANY1SPACE_BOOKING:')) {
      return value.replaceFirst('ANY1SPACE_BOOKING:', '').trim();
    }

    if (value.startsWith('ANY1SPACE-')) {
      return value.replaceFirst('ANY1SPACE-', '').trim();
    }

    return value;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getBookingFromQr(String raw) async {
    final bookingId = bookingIdFromQr(raw);

    if (bookingId.isEmpty) {
      throw Exception('Invalid QR code.');
    }

    final snap = await _db.collection('bookings').doc(bookingId).get();

    if (!snap.exists) {
      throw Exception('Booking not found.');
    }

    return snap;
  }

  Future<void> checkIn(String bookingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await _db.collection('bookings').doc(bookingId).set({
      'status': 'checkedIn',
      'checkedInAt': FieldValue.serverTimestamp(),
      'checkedInBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> checkOut(String bookingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await _db.collection('bookings').doc(bookingId).set({
      'status': 'checkedOut',
      'checkedOutAt': FieldValue.serverTimestamp(),
      'checkedOutBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
