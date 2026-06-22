import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/app_router.dart';
import '../config/admin_config.dart';

class RoleRedirectService {
  Future<String> dashboardRoute() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return AppRouter.welcome;
    }

    final email = user.email?.trim().toLowerCase();

    if (AdminConfig.isAdminEmail(email)) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'role': 'admin',
        'isAdmin': true,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return AppRouter.adminShell;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final status = (data['status'] ?? 'active').toString();

    if (status == 'blocked') {
      await FirebaseAuth.instance.signOut();
      return AppRouter.welcome;
    }

    final role = (data['role'] ?? 'driver').toString().toLowerCase();

    if (role == 'host') return AppRouter.hostShell;
    if (role == 'attendant') return AppRouter.attendantShell;
    if (role == 'admin') return AppRouter.adminShell;

    return AppRouter.driverShell;
  }
}
