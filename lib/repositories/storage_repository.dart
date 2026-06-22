import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 업로드. 사진은 `posts/{groupId}/...` 경로에 둔다.
/// 권한(그룹 ACTIVE 멤버)은 Storage 규칙이 강제한다.
class StorageRepository {
  StorageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final Random _random = Random();

  /// 로컬 파일을 그룹 게시물 경로에 업로드하고 다운로드 URL을 반환한다.
  Future<String> uploadPostPhoto({
    required String groupId,
    required String localPath,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final salt = _random.nextInt(1 << 32);
    final ext = _extensionOf(localPath);
    final ref = _storage.ref('posts/$groupId/${stamp}_$salt$ext');
    await ref.putFile(File(localPath));
    return ref.getDownloadURL();
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    return ext.length <= 5 ? ext : '.jpg';
  }
}
