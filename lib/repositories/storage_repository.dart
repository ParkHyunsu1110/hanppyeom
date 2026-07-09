import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 업로드. 사진은 `posts/{groupId}/...` 경로에 둔다.
/// 권한(그룹 ACTIVE 멤버)은 Storage 규칙이 강제한다.
class StorageRepository {
  StorageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final Random _random = Random();

  /// 사진 바이트를 그룹 게시물 경로에 업로드하고 다운로드 URL을 반환한다.
  ///
  /// 웹·모바일 공용으로 쓰려고 `dart:io` 파일이 아닌 바이트를 받는다.
  /// Storage 규칙이 `contentType == image/.*` 이고 10MB 미만일 때만 허용하므로,
  /// [contentType]을 [SettableMetadata]로 반드시 명시한다(putData는 자동 추론 안 함).
  Future<String> uploadPostPhoto({
    required String groupId,
    required Uint8List bytes,
    required String contentType,
    String? extension,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    // 1 << 32 는 웹(dart2js)에서 32비트로 잘려 0이 되어 nextInt가 RangeError를
    // 낸다. 32비트 안(1<<30)이면 웹·모바일 모두 안전하고, 타임스탬프와 조합 시
    // 파일명 충돌 방지엔 충분하다.
    final salt = _random.nextInt(1 << 30);
    final ext = _normalizeExtension(extension);
    final ref = _storage.ref('posts/$groupId/${stamp}_$salt$ext');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// 아이 프로필 사진을 `children/{groupId}/...` 경로에 업로드하고 URL을 반환한다.
  ///
  /// [uploadPostPhoto]와 같은 방식(바이트 기반·contentType 명시·32비트 안전 salt).
  /// Storage 규칙이 `contentType == image/.*` 이고 10MB 미만일 때만 허용한다.
  Future<String> uploadChildPhoto({
    required String groupId,
    required Uint8List bytes,
    required String contentType,
    String? extension,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final salt = _random.nextInt(1 << 30);
    final ext = _normalizeExtension(extension);
    final ref = _storage.ref('children/$groupId/profile_${stamp}_$salt$ext');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// 저장 파일명에 붙일 확장자(선행 점 포함, 소문자). 비었거나 이상하면 `.jpg`.
  String _normalizeExtension(String? extension) {
    if (extension == null || extension.isEmpty) return '.jpg';
    final ext = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';
    return ext.length <= 5 ? ext : '.jpg';
  }
}
