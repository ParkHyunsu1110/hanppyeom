import 'package:cloud_firestore/cloud_firestore.dart';

/// 앱 사용자(계정). Firestore `users/{uid}` 문서.
///
/// 이름이 `User`면 `firebase_auth`의 `User`와 충돌하므로 `AppUser`로 둔다.
/// 문서 ID = Firebase Auth uid.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  /// = Firebase Auth uid (문서 ID, 본문에는 저장하지 않음).
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
