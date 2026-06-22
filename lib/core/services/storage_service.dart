import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadSpacePhoto({
    required String hostId,
    required String spaceId,
    required File file,
  }) async {
    final ref = _storage.ref(
      'spaces/$hostId/$spaceId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
