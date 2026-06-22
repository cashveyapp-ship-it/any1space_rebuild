import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/profile_photo_service.dart';
import '../../../core/services/account_deletion_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickPhoto(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 900,
    );

    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final url = await ProfilePhotoService().uploadProfilePhoto(
        uid: user.uid,
        file: File(picked.path),
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': url,
        'profilePhoto': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updatePhotoURL(url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'photoUrl': '',
      'profilePhoto': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updatePhotoURL(null);

    if (mounted) setState(() {});
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose From Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _deleteAccountFlow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const SingleChildScrollView(
          child: Text(
            'This action cannot be undone.\n\n'
            'Before deletion, Any1Space will check for active bookings, pending payouts, unpaid shifts, open tickets, and open incidents.\n\n'
            'If anything is pending, your account cannot be deleted until those items are resolved.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = AccountDeletionService();

    final blocks = await service.deletionBlocks();

    if (!mounted) return;

    if (blocks.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete Account Yet'),
          content: SingleChildScrollView(
            child: Text(
              'Please resolve the following before deleting your account:\n\n'
              '${blocks.map((e) => '• $e').join('\n')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'No pending items were found. Your account will be marked for deletion and you will be signed out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    await service.requestOrDeleteAccount();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final name = (data['name'] ?? user?.displayName ?? 'User').toString();
          final email = (data['email'] ?? user?.email ?? '').toString();
          final role = (data['role'] ?? 'driver').toString();
          final photo = (data['photoUrl'] ?? data['profilePhoto'] ?? user?.photoURL ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: const Color(0xFFDDE8FF),
                      backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                      child: photo.isEmpty
                          ? const Icon(Icons.person_rounded, size: 58, color: Color(0xFF0B1F3A))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _uploading ? null : _showPhotoOptions,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF0B1F3A),
                          child: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(email, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_rounded),
                  title: const Text('Account Role'),
                  subtitle: Text(role),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Profile Photo'),
                  subtitle: const Text('Take, choose, change, or remove your profile image.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _uploading ? null : _showPhotoOptions,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_rounded),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _deleteAccountFlow,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Delete Account'),
                ),
              ),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


