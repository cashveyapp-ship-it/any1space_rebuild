import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';

class AdminIncidentsScreen extends StatelessWidget {
  final bool showBackButton;

  const AdminIncidentsScreen({
    super.key,
    this.showBackButton = true,
  });

  Future<void> _update(String id, String status) async {
    await FirebaseFirestore.instance.collection('incidents').doc(id).set({
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
        title: const Text('Incidents'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No incidents yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(data['type'] ?? 'Incident'),
                  subtitle: Text(
                    'Plate: ${data['licensePlate'] ?? ''}\n'
                    'Status: ${data['status'] ?? 'open'}\n'
                    '${data['notes'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => _update(doc.id, v),
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
