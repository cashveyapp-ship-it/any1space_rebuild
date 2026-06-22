import 'package:cloud_firestore/cloud_firestore.dart';

class BookingExpirationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> expireOldBookings() async {
    final now = Timestamp.fromDate(DateTime.now());

    final snap = await _db
        .collection('bookings')
        .where('status', whereIn: ['paid', 'reserved', 'confirmed'])
        .where('endTime', isLessThan: now)
        .get();

    final batch = _db.batch();

    for (final doc in snap.docs) {
      batch.set(doc.reference, {
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final data = doc.data();
      final spaceId = (data['spaceId'] ?? '').toString();

      if (spaceId.isNotEmpty) {
        batch.set(_db.collection('spaces').doc(spaceId), {
          'availableSpaces': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    if (snap.docs.isNotEmpty) {
      await batch.commit();
    }

    return snap.docs.length;
  }
}
