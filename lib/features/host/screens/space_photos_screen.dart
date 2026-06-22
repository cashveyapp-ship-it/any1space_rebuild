import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class SpacePhotosScreen extends StatefulWidget {
  final String spaceId;
  final String hostId;

  const SpacePhotosScreen({
    super.key,
    required this.spaceId,
    required this.hostId,
  });

  @override
  State<SpacePhotosScreen> createState() => _SpacePhotosScreenState();
}

class _SpacePhotosScreenState extends State<SpacePhotosScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    setState(() => _uploading = true);

    try {
      final urls = <String>[];

      for (final image in images) {
        final url = await StorageService().uploadSpacePhoto(
          hostId: widget.hostId,
          spaceId: widget.spaceId,
          file: File(image.path),
        );
        urls.add(url);
      }

      final ref = FirebaseFirestore.instance.collection('spaces').doc(widget.spaceId);
      final snap = await ref.get();
      final data = snap.data() ?? {};
      final currentGallery = List<String>.from(data['gallery'] ?? []);

      await ref.set({
        'coverPhoto': data['coverPhoto'] ?? urls.first,
        'gallery': [...currentGallery, ...urls],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _setCover(String url) async {
    await FirebaseFirestore.instance.collection('spaces').doc(widget.spaceId).set({
      'coverPhoto': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _removePhoto(String url) async {
    final ref = FirebaseFirestore.instance.collection('spaces').doc(widget.spaceId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final gallery = List<String>.from(data['gallery'] ?? []);
    gallery.remove(url);

    await ref.set({
      'gallery': gallery,
      if (data['coverPhoto'] == url) 'coverPhoto': gallery.isEmpty ? '' : gallery.first,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Space Photos'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('spaces').doc(widget.spaceId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final cover = (data['coverPhoto'] ?? '').toString();
          final gallery = List<String>.from(data['gallery'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(_uploading ? 'Uploading...' : 'Upload Photos'),
                ),
              ),
              const SizedBox(height: 20),
              if (cover.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(cover, height: 210, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: gallery.map((url) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(url, width: 110, height: 110, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'cover') _setCover(url);
                            if (v == 'remove') _removePhoto(url);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'cover', child: Text('Set as Cover')),
                            PopupMenuItem(value: 'remove', child: Text('Remove')),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
