import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/comment.dart';
import '../models/membership.dart';
import '../models/post.dart';

/// 가족 피드. 게시물 목록 + 좋아요 + 댓글 + 작성.
/// 공개범위(가족 전체 / 우리 부부만)는 Firestore 규칙이 강제한다.
class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.child,
    required this.myMembership,
  });

  final Child child;
  final Membership myMembership;

  bool get _isParent => myMembership.role == MemberRole.parent;
  String get _groupId => myMembership.groupId;
  String get _uid => myMembership.userId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${child.name} · 피드')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit),
        label: const Text('글쓰기'),
        onPressed: () => _compose(context),
      ),
      body: StreamBuilder<List<Post>>(
        stream: scope.feedRepository.watchPosts(
          groupId: _groupId,
          parentView: _isParent,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('피드를 불러오지 못했어요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('첫 게시물을 남겨보세요.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: posts.length,
            itemBuilder: (context, i) => _PostCard(post: posts[i], uid: _uid),
          );
        },
      ),
    );
  }

  Future<void> _compose(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ComposeSheet(canCouple: _isParent),
    );
    if (result == null) return;
    if (result.photos.isNotEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('사진을 올리는 중…')));
    }
    try {
      final urls = <String>[];
      for (final photo in result.photos) {
        urls.add(
          await scope.storageRepository.uploadPostPhoto(
            groupId: _groupId,
            bytes: photo.bytes,
            contentType: photo.contentType,
            extension: photo.extension,
          ),
        );
      }
      await scope.feedRepository.createPost(
        groupId: _groupId,
        authorId: _uid,
        caption: result.caption,
        visibility: result.visibility,
        photoUrls: urls,
      );
      messenger.showSnackBar(const SnackBar(content: Text('게시물을 올렸어요.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('등록에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.uid});

  final Post post;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 18),
                ),
                const SizedBox(width: 8),
                FutureBuilder(
                  future: scope.authService.fetchAppUser(post.authorId),
                  builder: (context, snap) =>
                      Text(snap.data?.displayName ?? '가족'),
                ),
                const Spacer(),
                if (post.visibility == PostVisibility.couple)
                  const Icon(Icons.lock, size: 16),
                const SizedBox(width: 4),
                Text(
                  _fmtTime(post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (post.caption.isNotEmpty) Text(post.caption),
            if (post.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PostPhotos(urls: post.photoUrls),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                StreamBuilder<Set<String>>(
                  stream: scope.feedRepository.watchLikeUserIds(post.id),
                  builder: (context, snap) {
                    final likes = snap.data ?? const <String>{};
                    final liked = likes.contains(uid);
                    return TextButton.icon(
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.redAccent : null,
                        size: 20,
                      ),
                      label: Text('${likes.length}'),
                      onPressed: () => scope.feedRepository.setLike(
                        postId: post.id,
                        userId: uid,
                        liked: !liked,
                      ),
                    );
                  },
                ),
                StreamBuilder<List<Comment>>(
                  stream: scope.feedRepository.watchComments(post.id),
                  builder: (context, snap) {
                    final count = snap.data?.length ?? 0;
                    return TextButton.icon(
                      icon: const Icon(Icons.mode_comment_outlined, size: 20),
                      label: Text('$count'),
                      onPressed: () => _openComments(context),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(postId: post.id, uid: uid),
    );
  }
}

class _PostPhotos extends StatelessWidget {
  const _PostPhotos({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _photo(urls.first, double.infinity, 220),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _photo(urls[i], 160, 160),
        ),
      ),
    );
  }

  Widget _photo(String url, double w, double h) {
    return Image.network(
      url,
      width: w,
      height: h,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : SizedBox(
              width: w,
              height: h,
              child: const Center(child: CircularProgressIndicator()),
            ),
      errorBuilder: (context, _, _) => Container(
        width: w == double.infinity ? null : w,
        height: h,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId, required this.uid});

  final String postId;
  final String uid;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final scope = AppScope.of(context);
    setState(() => _sending = true);
    try {
      await scope.feedRepository.addComment(
        postId: widget.postId,
        authorId: widget.uid,
        text: text,
      );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('댓글')),
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: scope.feedRepository.watchComments(widget.postId),
                builder: (context, snap) {
                  final comments = snap.data ?? const <Comment>[];
                  if (comments.isEmpty) {
                    return const Center(child: Text('첫 댓글을 남겨보세요.'));
                  }
                  return ListView.builder(
                    controller: controller,
                    itemCount: comments.length,
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      return ListTile(
                        leading: const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.person, size: 16),
                        ),
                        title: FutureBuilder(
                          future: scope.authService.fetchAppUser(c.authorId),
                          builder: (context, s) =>
                              Text(s.data?.displayName ?? '가족'),
                        ),
                        subtitle: Text(c.text),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '댓글 입력',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPost {
  const _NewPost(this.caption, this.visibility, this.photos);
  final String caption;
  final PostVisibility visibility;
  final List<_PickedPhoto> photos;
}

/// 웹·모바일 공용으로 다루는 첨부 사진(바이트 + 업로드 메타).
class _PickedPhoto {
  const _PickedPhoto({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
}

/// 파일명/경로에서 소문자 확장자(점 제외)를 뽑는다. 없으면 빈 문자열.
String _extensionOf(String nameOrPath) {
  final dot = nameOrPath.lastIndexOf('.');
  if (dot == -1 || dot == nameOrPath.length - 1) return '';
  final ext = nameOrPath.substring(dot + 1).toLowerCase();
  return ext.length <= 4 ? ext : '';
}

/// 확장자로부터 Storage 규칙(image/.*)을 통과할 contentType을 정한다.
String _contentTypeForExtension(String ext) {
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}

/// contentType으로부터 저장 파일명에 쓸 확장자를 정한다.
String _extensionForContentType(String contentType) {
  switch (contentType) {
    case 'image/png':
      return 'png';
    case 'image/gif':
      return 'gif';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
      return 'heic';
    default:
      return 'jpg';
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({required this.canCouple});

  final bool canCouple;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final List<_PickedPhoto> _photos = [];
  PostVisibility _visibility = PostVisibility.family;
  static const _maxPhotos = 4;
  static const _maxBytes = 10 * 1024 * 1024; // Storage 규칙: 10MB 미만

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final messenger = ScaffoldMessenger.of(context);
    // 화질을 낮춰 재인코딩하면 원본 대비 용량이 크게 줄고(10MB 규칙 대비),
    // iOS HEIC 원본도 JPEG로 변환돼 미리보기·업로드가 안정적이다.
    final picked = await _picker.pickMultiImage(
      limit: _maxPhotos,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    final loaded = <_PickedPhoto>[];
    var skipped = false;
    for (final x in picked) {
      if (_photos.length + loaded.length >= _maxPhotos) break;
      try {
        // 웹에서도 안전하게 바이트로 읽어 미리보기·업로드에 함께 쓴다.
        final bytes = await x.readAsBytes();
        if (bytes.lengthInBytes >= _maxBytes) {
          skipped = true;
          continue;
        }
        final ext = _extensionOf(x.name.isNotEmpty ? x.name : x.path);
        // mimeType가 있으면 우선, 없으면 확장자로 contentType을 정한다.
        final contentType = x.mimeType ?? _contentTypeForExtension(ext);
        final storageExt = ext.isNotEmpty
            ? ext
            : _extensionForContentType(contentType);
        loaded.add(
          _PickedPhoto(
            bytes: bytes,
            contentType: contentType,
            extension: storageExt,
          ),
        );
      } catch (_) {
        skipped = true;
      }
    }
    if (!mounted) return;
    if (loaded.isNotEmpty) setState(() => _photos.addAll(loaded));
    if (skipped) {
      messenger.showSnackBar(
        const SnackBar(content: Text('일부 사진은 용량이 크거나 열 수 없어 제외했어요. (최대 10MB)')),
      );
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _photos.isEmpty) return;
    Navigator.pop(context, _NewPost(text, _visibility, List.of(_photos)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('새 게시물', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(hintText: '오늘의 기록을 남겨보세요'),
          ),
          const SizedBox(height: 16),
          SegmentedButton<PostVisibility>(
            segments: [
              const ButtonSegment(
                value: PostVisibility.family,
                label: Text('가족 전체'),
                icon: Icon(Icons.group),
              ),
              ButtonSegment(
                value: PostVisibility.couple,
                label: const Text('우리 부부만'),
                icon: const Icon(Icons.lock),
                enabled: widget.canCouple,
              ),
            ],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
          ),
          if (!widget.canCouple)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '"우리 부부만"은 보호자만 작성할 수 있어요.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (_photos.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _photos[i].bytes,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, _) => Container(
                          width: 80,
                          height: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('사진 추가 (${_photos.length}/$_maxPhotos)'),
              onPressed: _photos.length >= _maxPhotos ? null : _pickPhotos,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: const Text('올리기')),
        ],
      ),
    );
  }
}

String _fmtTime(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  return '${d.month}.${d.day}';
}
