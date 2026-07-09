import 'package:cloud_firestore/cloud_firestore.dart';

/// 그룹 내 역할. 역할은 사용자나 아이가 아니라 멤버십(user↔group 연결)에 붙는다.
/// 같은 계정이 그룹마다 다른 역할일 수 있다. Firestore에는 wire 값으로 저장한다.
enum MemberRole {
  parent('PARENT'),
  relative('RELATIVE');

  const MemberRole(this.wire);
  final String wire;

  /// 알 수 없는 값은 최소 권한(relative)으로 폴백한다.
  static MemberRole fromWire(String? value) {
    for (final r in MemberRole.values) {
      if (r.wire == value) return r;
    }
    return MemberRole.relative;
  }
}

/// 관계 호칭 타입. 권한(role)과는 완전히 분리된 표시용 값이다.
/// Firestore에는 안정적 wire 코드로 저장하고, UI에는 한글 [label]을 쓴다.
/// [etc](기타)는 자유 입력을 허용하며, 이때 입력값은 [Membership.relationLabel]에 담는다.
enum RelationType {
  grandmaP('GRANDMA_P', '할머니'),
  grandpaP('GRANDPA_P', '할아버지'),
  grandmaM('GRANDMA_M', '외할머니'),
  grandpaM('GRANDPA_M', '외할아버지'),
  imo('IMO', '이모'),
  imobu('IMOBU', '이모부'),
  gomo('GOMO', '고모'),
  gomobu('GOMOBU', '고모부'),
  samchon('SAMCHON', '삼촌'),
  oesamchon('OESAMCHON', '외삼촌'),
  sukmo('SUKMO', '숙모'),
  oesukmo('OESUKMO', '외숙모'),
  sachon('SACHON', '사촌'),
  etc('ETC', '기타');

  const RelationType(this.wire, this.label);
  final String wire;
  final String label;

  /// 알 수 없는/없는 값은 null(호칭 미지정 또는 legacy)로 폴백한다.
  static RelationType? fromWire(String? v) {
    for (final t in RelationType.values) {
      if (t.wire == v) return t;
    }
    return null;
  }
}

/// 멤버십 상태. PENDING은 그룹 데이터에 접근할 수 없다(초대 승인 대기).
enum MembershipStatus {
  active('ACTIVE'),
  pending('PENDING');

  const MembershipStatus(this.wire);
  final String wire;

  /// 알 수 없는 값은 접근 불가(pending)로 폴백한다.
  static MembershipStatus fromWire(String? value) {
    for (final s in MembershipStatus.values) {
      if (s.wire == value) return s;
    }
    return MembershipStatus.pending;
  }
}

/// 멤버십(user↔group 연결). ⭐ Phase 1의 핵심.
///
/// 문서 ID = `{groupId}_{userId}` → 조인 없이 get/exists 한 번으로 검증한다
/// (Firestore 규칙이 단순·빠름). [docId]로 ID를 만든다.
class Membership {
  const Membership({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.role,
    required this.isAdmin,
    required this.status,
    this.relationType,
    this.relationLabel,
  });

  /// 문서 ID = `{groupId}_{userId}`(본문에는 저장하지 않음).
  final String id;
  final String userId;
  final String groupId;
  final MemberRole role;

  /// 관계 호칭 타입(예: 이모, 삼촌). UI 표시용, 권한과 무관.
  /// 없으면(null) 호칭 미지정 또는 구 데이터(legacy [relationLabel]) 이다.
  final RelationType? relationType;

  /// [RelationType.etc] 선택 시 자유 입력한 호칭 텍스트, 또는 구 데이터의
  /// legacy 호칭 문자열. 표시 규칙은 `relationTitle`을 따른다.
  final String? relationLabel;

  /// 멤버 관리·코드 재발급 권한(보호자 중 관리자만).
  final bool isAdmin;
  final MembershipStatus status;

  /// 멤버십 문서 ID 규칙.
  static String docId(String groupId, String userId) => '${groupId}_$userId';

  factory Membership.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Membership(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      role: MemberRole.fromWire(data['role'] as String?),
      relationType: RelationType.fromWire(data['relationType'] as String?),
      relationLabel: data['relationLabel'] as String?,
      isAdmin: data['isAdmin'] as bool? ?? false,
      status: MembershipStatus.fromWire(data['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'userId': userId,
    'groupId': groupId,
    'role': role.wire,
    'relationType': relationType?.wire,
    'relationLabel': relationLabel,
    'isAdmin': isAdmin,
    'status': status.wire,
  };

  Membership copyWith({
    MemberRole? role,
    RelationType? relationType,
    String? relationLabel,
    bool? isAdmin,
    MembershipStatus? status,
  }) {
    return Membership(
      id: id,
      userId: userId,
      groupId: groupId,
      role: role ?? this.role,
      relationType: relationType ?? this.relationType,
      relationLabel: relationLabel ?? this.relationLabel,
      isAdmin: isAdmin ?? this.isAdmin,
      status: status ?? this.status,
    );
  }
}
