import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';

class NotificationsScreen extends StatelessWidget {
  final bool showBackButton;

  const NotificationsScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _notifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _markRead(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).set({
      'read': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final read = data['read'] == true;

              return Card(
                child: ListTile(
                  leading: Icon(
                    read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(data['body'] ?? ''),
                  trailing: read
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.check_rounded),
                          onPressed: () => _markRead(doc.id),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
