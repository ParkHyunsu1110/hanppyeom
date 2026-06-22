import 'package:cloud_firestore/cloud_firestore.dart';

/// 게시물 공개범위. COUPLE은 PARENT 역할 멤버만 읽을 수 있다(규칙에서 강제).
enum PostVisibility {
  family('FAMILY'),
  couple('COUPLE');

  const PostVisibility(this.wire);
  final String wire;

  static PostVisibility fromWire(String? value) {
    for (final v in PostVisibility.values) {
      if (v.wire == value) return v;
    }
    return PostVisibility.family;
  }
}

/// 피드 게시물. Firestore `posts/{postId}`.
/// 프로토타입은 캡션 중심(사진 업로드는 후속) — photoUrls는 비어 있을 수 있다.
class Post {
  const Post({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.caption,
    required this.photoUrls,
    required this.visibility,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String authorId;
  final String caption;
  final List<String> photoUrls;
  final PostVisibility visibility;
  final DateTime createdAt;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Post(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      photoUrls:
          (data['photoUrls'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      visibility: PostVisibility.fromWire(data['visibility'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'groupId': groupId,
    'authorId': authorId,
    'caption': caption,
    'photoUrls': photoUrls,
    'visibility': visibility.wire,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
