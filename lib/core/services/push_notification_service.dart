import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    await _saveToken(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
