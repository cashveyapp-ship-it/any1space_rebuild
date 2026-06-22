import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';

class HostDisputesScreen extends StatelessWidget {
  final bool showBackButton;

  const HostDisputesScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _tickets() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('supportTickets')
        .where('hostId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('supportTickets').doc(id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Disputes & Claims'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _tickets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No host disputes or claims yet.',
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

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_rounded),
                  title: Text(data['subject'] ?? data['category'] ?? 'Claim'),
                  subtitle: Text(
                    'Status: ${data['status'] ?? 'open'}\n${data['message'] ?? data['details'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => _updateStatus(doc.id, v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'open', child: Text('Open')),
                      PopupMenuItem(value: 'inReview', child: Text('In Review')),
                      PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                      PopupMenuItem(value: 'closed', child: Text('Closed')),
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
