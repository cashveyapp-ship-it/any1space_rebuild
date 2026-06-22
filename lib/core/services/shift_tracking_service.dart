import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShiftTrackingService {
  final _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>?> activeShift() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await _db
        .collection('attendantShifts')
        .where('attendantId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<void> startShift() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Attendant must be signed in.');

    final existing = await activeShift();
    if (existing != null) throw Exception('You already have an active shift.');

    final assigned = await _db
        .collection('assignedSpaces')
        .where('attendantKeys', arrayContainsAny: [user.uid, user.email ?? ''])
        .limit(1)
        .get();

    if (assigned.docs.isEmpty) {
      throw Exception('You must be assigned to a space before starting a shift.');
    }

    final assignment = assigned.docs.first.data();

    final attendantSnap = await _db
        .collection('attendants')
        .where('email', isEqualTo: (user.email ?? '').toLowerCase())
        .limit(1)
        .get();

    final attendantData = attendantSnap.docs.isEmpty ? <String, dynamic>{} : attendantSnap.docs.first.data();
    final hourlyRate = ((attendantData['hourlyRate'] ?? 0) as num).toDouble();

    await _db.collection('attendantShifts').add({
      'attendantId': user.uid,
      'attendantEmail': user.email ?? '',
      'attendantName': attendantData['name'] ?? user.email ?? 'Attendant',
      'hostId': assignment['hostId'] ?? '',
      'spaceId': assignment['spaceId'] ?? '',
      'spaceName': assignment['spaceName'] ?? '',
      'hourlyRate': hourlyRate,
      'status': 'active',
      'paymentStatus': 'unpaid',
      'startedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endShift(String shiftId, Timestamp startedAt, double hourlyRate) async {
    final end = DateTime.now();
    final start = startedAt.toDate();
    final minutes = end.difference(start).inMinutes;
    final hours = minutes / 60;
    final estimatedPay = hours * hourlyRate;

    await _db.collection('attendantShifts').doc(shiftId).set({
      'status': 'completed',
      'endedAt': Timestamp.fromDate(end),
      'minutesWorked': minutes,
      'hoursWorked': hours,
      'estimatedPay': estimatedPay,
      'paymentStatus': 'pendingHostReview',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myShifts() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _db
        .collection('attendantShifts')
        .where('attendantId', isEqualTo: uid)
        .snapshots();
  }
}
