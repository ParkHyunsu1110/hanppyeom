import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';
import '../models/post.dart';

/// 피드(게시물/좋아요/댓글). 공개범위·권한은 Firestore 규칙이 강제한다.
///
/// 좋아요/댓글의 공개범위는 글에서 상속된다(친척은 COUPLE 글을 못 읽으므로
/// 그 글의 좋아요·댓글도 자동 차단).
class FeedRepository {
  FeedRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');
  CollectionReference<Map<String, dynamic>> get _likes =>
      _firestore.collection('likes');
  CollectionReference<Map<String, dynamic>> get _comments =>
      _firestore.collection('comments');

  Future<String> createPost({
    required String groupId,
    required String authorId,
    required String caption,
    required PostVisibility visibility,
    List<String> photoUrls = const [],
  }) async {
    final ref = _posts.doc();
    final post = Post(
      id: ref.id,
      groupId: groupId,
      authorId: authorId,
      caption: caption,
      photoUrls: photoUrls,
      visibility: visibility,
      createdAt: DateTime.now(),
    );
    await ref.set(post.toMap());
    return ref.id;
  }

  Future<void> deletePost(String postId) => _posts.doc(postId).delete();

  /// 피드 구독. 친척(비부모)은 COUPLE 글을 읽을 수 없으므로 FAMILY만 질의해야
  /// 규칙 위반으로 쿼리가 실패하지 않는다.
  Stream<List<Post>> watchPosts({
    required String groupId,
    required bool parentView,
  }) {
    Query<Map<String, dynamic>> q = _posts.where('groupId', isEqualTo: groupId);
    if (!parentView) {
      q = q.where('visibility', isEqualTo: PostVisibility.family.wire);
    }
    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Post.fromDoc).toList());
  }

  // ── 좋아요 ───────────────────────────────────────────────
  String _likeId(String postId, String userId) => '${postId}_$userId';

  Future<void> setLike({
    required String postId,
    required String userId,
    required bool liked,
  }) {
    final doc = _likes.doc(_likeId(postId, userId));
    return liked ? doc.set({'postId': postId, 'userId': userId}) : doc.delete();
  }

  Stream<Set<String>> watchLikeUserIds(String postId) => _likes
      .where('postId', isEqualTo: postId)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()['userId'] as String).toSet());

  // ── 댓글 ─────────────────────────────────────────────────
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String text,
  }) {
    return _comments.add(
      Comment(
        id: '',
        postId: postId,
        authorId: authorId,
        text: text,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Stream<List<Comment>> watchComments(String postId) => _comments
      .where('postId', isEqualTo: postId)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Comment.fromDoc).toList());
}
