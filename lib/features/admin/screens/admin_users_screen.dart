import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';

class AdminUsersScreen extends StatelessWidget {
  final bool showBackButton;

  const AdminUsersScreen({
    super.key,
    this.showBackButton = true,
  });

  Future<void> _setStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('users').doc(id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteUserDoc(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  'Users failed to load:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            );
          }

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data();
              final status = (data['status'] ?? 'active').toString();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(status == 'blocked' ? Icons.block_rounded : Icons.person_rounded),
                  ),
                  title: Text(
                    data['name'] ?? data['email'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Role: ${data['role'] ?? 'driver'}\n'
                    'Status: $status\n'
                    '${data['email'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'block') await _setStatus(doc.id, 'blocked');
                      if (value == 'active') await _setStatus(doc.id, 'active');
                      if (value == 'delete') await _deleteUserDoc(doc.id);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'active', child: Text('Unblock / Activate')),
                      PopupMenuItem(value: 'block', child: Text('Block User')),
                      PopupMenuItem(value: 'delete', child: Text('Delete User Record')),
                    ],
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
