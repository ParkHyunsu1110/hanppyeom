import '../models/membership.dart';

/// 멤버십의 호칭을 사람이 읽는 라벨로 바꾼다. 없으면 null.
///
/// - [relationType]이 있으면 그 라벨을 쓴다. 단 [RelationType.etc]는
///   자유 입력([Membership.relationLabel])이 있으면 그 값을, 비면 '기타'를 쓴다.
/// - [relationType]이 없으면 구 데이터로 보고 legacy [Membership.relationLabel]로
///   폴백한다(비어 있으면 null).
String? relationTitle(Membership m) {
  final type = m.relationType;
  if (type != null) {
    if (type == RelationType.etc) {
      final custom = m.relationLabel;
      return custom != null && custom.isNotEmpty
          ? custom
          : RelationType.etc.label;
    }
    return type.label;
  }
  final legacy = m.relationLabel;
  return legacy != null && legacy.isNotEmpty ? legacy : null;
}

/// 멤버십을 사람이 읽는 라벨로 바꾸는 UI 헬퍼.
/// 호칭이 있으면 호칭을, 없으면 역할 기본 라벨('부모'/'친척')을 쓴다.
String roleLabel(Membership m) {
  final title = relationTitle(m);
  if (title != null) return title;
  switch (m.role) {
    case MemberRole.parent:
      return '부모';
    case MemberRole.relative:
      return '친척';
  }
}

/// 역할 뱃지에 함께 표시할 보조 텍스트(관리자 등).
String? roleSuffix(Membership m) => m.isAdmin ? '관리자' : null;
