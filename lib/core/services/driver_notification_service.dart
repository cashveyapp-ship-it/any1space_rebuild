import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverNotificationService {
  Stream<QuerySnapshot<Map<String, dynamic>>> myNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots();
  }

  Stream<int> unreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markRead(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .set({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteNotification(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}
