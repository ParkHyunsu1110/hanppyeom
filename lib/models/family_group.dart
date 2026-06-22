import 'package:cloud_firestore/cloud_firestore.dart';

/// 가족 그룹. Firestore `groups/{groupId}` 문서. 아이([Child]) 1명당 1개.
///
/// 부부 동기화·친척 추가·게시물 공개범위가 모두 이 그룹과 [Membership] 위에서 풀린다.
class FamilyGroup {
  const FamilyGroup({
    required this.id,
    required this.childId,
    required this.inviteCode,
  });

  /// 문서 ID(본문에는 저장하지 않음).
  final String id;

  /// 이 그룹이 속한 아이.
  final String childId;

  /// 초대 코드. 코드 입력 → PENDING 멤버십 생성 → 관리자 승인 흐름의 시작점.
  final String inviteCode;

  factory FamilyGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FamilyGroup(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'childId': childId,
    'inviteCode': inviteCode,
  };

  FamilyGroup copyWith({String? childId, String? inviteCode}) {
    return FamilyGroup(
      id: id,
      childId: childId ?? this.childId,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}
