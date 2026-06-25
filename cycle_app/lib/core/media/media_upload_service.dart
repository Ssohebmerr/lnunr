import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaUploadService {
  MediaUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _picker = ImagePicker();

  Future<XFile?> pickImage() => _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );

  Future<XFile?> pickVideo() => _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

  Future<String> uploadCommunityPostMedia({
    required String uid,
    required String communityId,
    required XFile file,
    required bool isVideo,
  }) async {
    final ext = isVideo ? 'mp4' : 'jpg';
    final path =
        'community_media/$communityId/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child(path);
    await ref.putFile(
      File(file.path),
      SettableMetadata(
        contentType: isVideo ? 'video/mp4' : 'image/jpeg',
      ),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile file,
  }) async {
    final path = 'profile_photos/$uid/avatar.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
