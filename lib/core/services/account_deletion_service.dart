import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDeletionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<String>> deletionBlocks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return ['You must be signed in.'];

    final uid = user.uid;
    final blocks = <String>[];

    final activeBookings = await _db
        .collection('bookings')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'paid', 'reserved', 'confirmed', 'checkedIn'])
        .limit(1)
        .get();

    if (activeBookings.docs.isNotEmpty) {
      blocks.add('You have an active or pending booking.');
    }

    final hostBookings = await _db
        .collection('bookings')
        .where('hostId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'paid', 'reserved', 'confirmed', 'checkedIn'])
        .limit(1)
        .get();

    if (hostBookings.docs.isNotEmpty) {
      blocks.add('You have active host bookings.');
    }

    final openTickets = await _db
        .collection('supportTickets')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['open', 'inReview', 'escalatedToAdmin'])
        .limit(1)
        .get();

    if (openTickets.docs.isNotEmpty) {
      blocks.add('You have an open support ticket or dispute.');
    }

    final hostTickets = await _db
        .collection('supportTickets')
        .where('hostId', isEqualTo: uid)
        .where('status', whereIn: ['open', 'inReview', 'escalatedToAdmin'])
        .limit(1)
        .get();

    if (hostTickets.docs.isNotEmpty) {
      blocks.add('You have open host support tickets.');
    }

    final openIncidents = await _db
        .collection('incidents')
        .where('attendantId', isEqualTo: uid)
        .where('status', whereIn: ['open', 'inReview', 'escalatedToAdmin'])
        .limit(1)
        .get();

    if (openIncidents.docs.isNotEmpty) {
      blocks.add('You have an open incident report.');
    }

    final hostIncidents = await _db
        .collection('incidents')
        .where('hostId', isEqualTo: uid)
        .where('status', whereIn: ['open', 'inReview', 'escalatedToAdmin'])
        .limit(1)
        .get();

    if (hostIncidents.docs.isNotEmpty) {
      blocks.add('You have open host incidents.');
    }

    final assignedSpaces = await _db
        .collection('assignedSpaces')
        .where('attendantId', isEqualTo: uid)
        .where('status', isEqualTo: 'assigned')
        .limit(1)
        .get();

    if (assignedSpaces.docs.isNotEmpty) {
      blocks.add('You are still assigned to active spaces.');
    }

    final pendingPayouts = await _db
        .collection('payouts')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'processing'])
        .limit(1)
        .get();

    if (pendingPayouts.docs.isNotEmpty) {
      blocks.add('You have a pending payout.');
    }

    final pendingShiftPayments = await _db
        .collection('shiftPayments')
        .where('attendantId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'processing', 'unpaid'])
        .limit(1)
        .get();

    if (pendingShiftPayments.docs.isNotEmpty) {
      blocks.add('You have pending attendant shift payment.');
    }

    return blocks;
  }

  Future<void> requestOrDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You must be signed in.');

    final uid = user.uid;
    final email = user.email ?? '';

    await _db.collection('accountDeletionRequests').doc(uid).set({
      'userId': uid,
      'email': email,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'status': 'deletionRequested',
      'deletionRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmToken': '',
      'notificationsEnabled': false,
    }, SetOptions(merge: true));

    await FirebaseAuth.instance.signOut();
  }
}
