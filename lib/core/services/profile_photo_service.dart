import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref(
      'users/$uid/profile/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
