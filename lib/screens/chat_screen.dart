import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/chat_message.dart';
import '../models/child.dart';
import '../models/membership.dart';
import '../theme/toss_theme.dart';

/// 가족 그룹 단체 채팅. ACTIVE 멤버면 누구나 대화한다(보낸 사람 이름 표시).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.child,
    required this.myMembership,
  });

  final Child child;
  final Membership myMembership;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  String get _groupId => widget.myMembership.groupId;
  String get _uid => widget.myMembership.userId;
  bool get _isAdmin => widget.myMembership.isAdmin;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 확인 다이얼로그 후 메시지를 삭제한다(보낸 사람 또는 관리자).
  Future<void> _confirmDelete(ChatMessage message) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 메시지를 삭제해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await scope.chatRepository.deleteMessage(message.id);
      messenger.showSnackBar(const SnackBar(content: Text('삭제했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final scope = AppScope.of(context);
    setState(() => _sending = true);
    try {
      await scope.chatRepository.send(
        groupId: _groupId,
        senderId: _uid,
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
    return Scaffold(
      appBar: AppBar(title: Text('${widget.child.name} · 채팅')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: scope.chatRepository.watchMessages(_groupId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('대화를 불러오지 못했어요.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('첫 메시지를 보내보세요.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMine = m.senderId == _uid;
                    return _Bubble(
                      message: m,
                      isMine: isMine,
                      // 보낸 사람 또는 관리자만 길게 눌러 삭제(규칙과 일치).
                      onDelete: (isMine || _isAdmin)
                          ? () => _confirmDelete(m)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sending ? null : _send(),
                      decoration: const InputDecoration(
                        hintText: '메시지 입력',
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
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine, this.onDelete});

  final ChatMessage message;
  final bool isMine;

  /// 길게 누르면 호출(삭제 가능할 때만 전달). null이면 삭제 진입 없음.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = AppScope.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: FutureBuilder(
                future: scope.authService.fetchAppUser(message.senderId),
                builder: (context, snap) => Text(
                  snap.data?.displayName ?? '가족',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onDelete,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMine ? scheme.primary : scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMine ? scheme.onPrimary : TossColors.g800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
