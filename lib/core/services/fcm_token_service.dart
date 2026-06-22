import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  static Future<void> saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();

    if (token == null || token.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationsEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'fcmToken': newToken,
        'fcmTokens': FieldValue.arrayUnion([newToken]),
        'notificationsEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
