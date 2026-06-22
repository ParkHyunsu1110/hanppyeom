import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

/// 그룹 단위 단체 대화. ACTIVE 멤버면 누구나 읽고 쓸 수 있다(규칙 강제).
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('chatMessages');

  Future<void> send({
    required String groupId,
    required String senderId,
    required String text,
  }) {
    return _messages.add(
      ChatMessage(
        id: '',
        groupId: groupId,
        senderId: senderId,
        text: text,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  /// 시간 오름차순(오래된→최신) 구독.
  Stream<List<ChatMessage>> watchMessages(String groupId) => _messages
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
}
