import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/space_model.dart';

class SpaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<SpaceModel>> streamActiveSpaces() {
    return _db
        .collection('spaces')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SpaceModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<SpaceModel>> streamMySpaces() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('spaces')
        .where('hostId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SpaceModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createSpace({
    required String name,
    required String address,
    required int totalSpaces,
    required double hourlyPrice,
    required double dailyPrice,
    String spaceType = 'Parking',
    String rules = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be signed in.');

    final doc = _db.collection('spaces').doc();

    await doc.set({
      'id': doc.id,
      'hostId': user.uid,
      'name': name,
      'address': address,
      'latitude': 33.7490,
      'longitude': -84.3880,
      'totalSpaces': totalSpaces,
      'availableSpaces': totalSpaces,
      'hourlyPrice': hourlyPrice,
      'dailyPrice': dailyPrice,
      'spaceType': spaceType,
      'rules': rules,
      'isActive': true,
      'stripeAccountId': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleSpace(String spaceId, bool value) async {
    await _db.collection('spaces').doc(spaceId).set({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
