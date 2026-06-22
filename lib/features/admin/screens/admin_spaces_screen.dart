import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';

class AdminSpacesScreen extends StatelessWidget {
  final bool showBackButton;

  const AdminSpacesScreen({
    super.key,
    this.showBackButton = true,
  });

  Future<void> _toggle(String id, bool active) async {
    await FirebaseFirestore.instance.collection('spaces').doc(id).set({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Spaces'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('spaces').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data();
              final active = data['isActive'] == true;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_parking_rounded),
                  title: Text(data['name'] ?? 'Space'),
                  subtitle: Text('${data['address'] ?? ''}\nHost: ${data['hostId'] ?? ''}'),
                  isThreeLine: true,
                  trailing: Switch(
                    value: active,
                    onChanged: (v) => _toggle(doc.id, v),
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
