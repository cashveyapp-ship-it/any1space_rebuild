import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/space_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<BookingModel>> streamDriverBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('bookings')
        .where('driverId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BookingModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<BookingModel>> streamHostBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('bookings')
        .where('hostId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BookingModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<BookingModel>> streamPaidBookings() {
    return _db.collection('bookings')
        .where('status', whereIn: ['paid', 'checkedIn'])
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BookingModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<String> createPendingBooking({
    required SpaceModel space,
    required String licensePlate,
    required double amount,
    String? spaceNumber,
    int hours = 1,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be signed in.');

    final doc = _db.collection('bookings').doc();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(hours: hours));

    await doc.set({
      'id': doc.id,
      'driverId': user.uid,
      'driverEmail': user.email ?? '',
      'hostId': space.hostId,
      'spaceId': space.id,
      'spaceName': space.name,
      'spaceAddress': space.address,
      'spaceNumber': spaceNumber ?? '',
      'licensePlate': licensePlate.trim().toUpperCase(),
      'amount': amount,
      'platformFee': amount * 0.20,
      'hostPayout': amount * 0.80,
      'hours': hours,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': 'pending',
      'paymentStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> checkIn(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).set({
      'status': 'checkedIn',
      'checkedInAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> checkOut(String bookingId) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(bookingRef);
      final data = snap.data() ?? {};

      final spaceId = (data['spaceId'] ?? '').toString();
      final number = (data['spaceNumber'] ?? '').toString();

      tx.set(bookingRef, {
        'status': 'checkedOut',
        'checkedOutAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (spaceId.isNotEmpty && number.isNotEmpty) {
        tx.set(_db.collection('spaces').doc(spaceId), {
          'occupiedSpaceNumbers': FieldValue.arrayRemove([number]),
          'availableSpaces': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).set({
      'status': 'cancelled',
      'paymentStatus': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
