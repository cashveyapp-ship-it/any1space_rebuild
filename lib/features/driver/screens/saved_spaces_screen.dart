import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'space_details_screen.dart';

class SavedSpacesScreen extends StatelessWidget {
  final bool showBackButton;

  const SavedSpacesScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _saved() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedSpaces')
        .snapshots();
  }

  Future<void> _remove(String spaceId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedSpaces')
        .doc(spaceId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Saved Spaces'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _saved(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No saved spaces yet.',
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
              final spaceId = (data['spaceId'] ?? doc.id).toString();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.favorite_rounded),
                  title: Text(data['name'] ?? 'Saved Space'),
                  subtitle: Text(data['address'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _remove(spaceId),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpaceDetailsScreen(spaceId: spaceId),
                    ),
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


