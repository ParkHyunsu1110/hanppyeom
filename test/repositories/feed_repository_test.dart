import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/feed_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late FeedRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FeedRepository(firestore: fs);
  });

  test(
    'updatePost는 caption/visibility만 바꾸고 groupId·authorId·사진은 유지한다',
    () async {
      final id = await repo.createPost(
        groupId: 'g1',
        authorId: 'u1',
        caption: '처음 캡션',
        visibility: PostVisibility.family,
        photoUrls: const ['http://p/1.jpg'],
      );

      await repo.updatePost(
        postId: id,
        caption: '수정된 캡션',
        visibility: PostVisibility.couple,
      );

      final snap = await fs.collection('posts').doc(id).get();
      expect(snap.data()!['caption'], '수정된 캡션');
      expect(snap.data()!['visibility'], 'COUPLE');
      // 규칙(groupId·authorId 불변) + 사진 유지(범위 밖)를 검증.
      expect(snap.data()!['groupId'], 'g1');
      expect(snap.data()!['authorId'], 'u1');
      expect(snap.data()!['photoUrls'], ['http://p/1.jpg']);
    },
  );

  test('deletePost는 문서를 제거한다', () async {
    final id = await repo.createPost(
      groupId: 'g1',
      authorId: 'u1',
      caption: '지울 글',
      visibility: PostVisibility.family,
    );

    await repo.deletePost(id);

    final snap = await fs.collection('posts').doc(id).get();
    expect(snap.exists, isFalse);
  });

  test('deleteComment는 해당 댓글만 제거한다', () async {
    await repo.addComment(postId: 'p1', authorId: 'u1', text: '첫 댓글');
    var comments = await repo.watchComments('p1').first;
    expect(comments.length, 1);

    await repo.deleteComment(comments.first.id);

    comments = await repo.watchComments('p1').first;
    expect(comments, isEmpty);
  });
}
