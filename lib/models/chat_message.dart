import 'package:cloud_firestore/cloud_firestore.dart';

/// 가족 그룹 단체 대화 메시지. Firestore `chatMessages/{id}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.attachmentUrl,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String text;
  final String? attachmentUrl;
  final DateTime createdAt;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'groupId': groupId,
    'senderId': senderId,
    'text': text,
    'attachmentUrl': attachmentUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
