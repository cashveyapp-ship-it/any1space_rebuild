import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/app_router.dart';

class UserStatusService {
  Future<bool> isCurrentUserBlocked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};
    final status = (data['status'] ?? 'active').toString().toLowerCase();

    return status == 'blocked' ||
        status == 'banned' ||
        status == 'suspended';
  }

  Future<String?> blockedRedirectRoute() async {
    final blocked = await isCurrentUserBlocked();

    if (!blocked) return null;

    await FirebaseAuth.instance.signOut();
    return AppRouter.welcome;
  }
}
