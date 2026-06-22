import '../models/membership.dart';

/// 멤버십을 사람이 읽는 라벨로 바꾸는 UI 헬퍼.
String roleLabel(Membership m) {
  switch (m.role) {
    case MemberRole.parent:
      return m.relationLabel?.isNotEmpty == true ? m.relationLabel! : '부모';
    case MemberRole.relative:
      return m.relationLabel?.isNotEmpty == true ? m.relationLabel! : '친척';
  }
}

/// 역할 뱃지에 함께 표시할 보조 텍스트(관리자 등).
String? roleSuffix(Membership m) => m.isAdmin ? '관리자' : null;
