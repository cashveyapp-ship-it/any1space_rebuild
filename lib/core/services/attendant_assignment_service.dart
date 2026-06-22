import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/assigned_space_model.dart';

class AttendantAssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamHostAttendants() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('attendants')
        .where('hostId', isEqualTo: uid)
        .snapshots();
  }

  Stream<List<AssignedSpaceModel>> streamMyAssignedSpaces() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final email = (user.email ?? '').toLowerCase();

    return _db
        .collection('assignedSpaces')
        .where('attendantKeys', arrayContainsAny: [
          user.uid,
          email,
        ])
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AssignedSpaceModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addAttendant({
    required String name,
    required String email,
    double hourlyRate = 0,
  }) async {
    final host = FirebaseAuth.instance.currentUser;
    if (host == null) throw Exception('Host must be signed in.');

    final cleanEmail = email.trim().toLowerCase();
    final doc = _db.collection('attendants').doc();

    await doc.set({
      'id': doc.id,
      'hostId': host.uid,
      'name': name.trim(),
      'email': cleanEmail,
      'attendantId': '',
      'attendantUid': '',
      'attendantKeys': [cleanEmail],
      'hourlyRate': hourlyRate,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignSpace({
    required String hostId,
    required String attendantId,
    required String spaceId,
    required String spaceName,
    String attendantEmail = '',
    String attendantName = '',
  }) async {
    final cleanEmail = attendantEmail.trim().toLowerCase();
    final keys = <String>{attendantId};
    if (cleanEmail.isNotEmpty) keys.add(cleanEmail);

    final doc = _db.collection('assignedSpaces').doc();

    await doc.set({
      'id': doc.id,
      'hostId': hostId,
      'attendantId': attendantId,
      'attendantEmail': cleanEmail,
      'attendantName': attendantName,
      'attendantKeys': keys.toList(),
      'spaceId': spaceId,
      'spaceName': spaceName,
      'status': 'assigned',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
