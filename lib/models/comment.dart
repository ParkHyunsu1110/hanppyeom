import 'package:cloud_firestore/cloud_firestore.dart';

/// 게시물 댓글. Firestore `comments/{commentId}`. 공개범위는 글에서 상속(규칙).
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Comment(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'postId': postId,
    'authorId': authorId,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
