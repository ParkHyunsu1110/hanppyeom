import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership.dart';
import 'repository_exceptions.dart';

/// 멤버십 참여(초대 코드)·승인·조회. 역할/상태 전이의 클라이언트 진입점.
///
/// 실제 권한은 Firestore 규칙이 강제한다(여기서의 호출은 규칙 위반 시 거부됨).
class MembershipRepository {
  MembershipRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _memberships =>
      _firestore.collection('memberships');
  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('inviteCodes');

  /// 초대 코드로 참여한다. 친척(RELATIVE)·승인 대기(PENDING) 멤버십을 만든다.
  ///
  /// 코드가 없으면 [InviteCodeNotFoundException], 이미 멤버/대기면
  /// [AlreadyJoinedException]를 던진다.
  Future<void> joinByInviteCode({
    required String uid,
    required String code,
    String? relationLabel,
  }) async {
    final normalized = code.trim().toUpperCase();
    final codeSnap = await _inviteCodes.doc(normalized).get();
    if (!codeSnap.exists) {
      throw InviteCodeNotFoundException(normalized);
    }
    final groupId = codeSnap.data()!['groupId'] as String;
    final membershipId = Membership.docId(groupId, uid);
    final ref = _memberships.doc(membershipId);

    if ((await ref.get()).exists) {
      throw AlreadyJoinedException(groupId);
    }

    final membership = Membership(
      id: membershipId,
      userId: uid,
      groupId: groupId,
      role: MemberRole.relative,
      isAdmin: false,
      status: MembershipStatus.pending,
      relationLabel: relationLabel,
    );
    await ref.set(membership.toMap());
  }

  /// 관리자가 승인한다(PENDING → ACTIVE). 멱등.
  Future<void> approve(String membershipId) =>
      _memberships.doc(membershipId).update({
        'status': MembershipStatus.active.wire,
      });

  /// 관리자가 거절/제거하거나, 본인이 탈퇴한다.
  Future<void> remove(String membershipId) =>
      _memberships.doc(membershipId).delete();

  /// 내가 속한(또는 대기 중인) 모든 멤버십. 시작 선택 화면에서 사용.
  Stream<List<Membership>> watchMyMemberships(String uid) => _memberships
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((q) => q.docs.map(Membership.fromDoc).toList());

  /// 한 그룹의 전체 멤버. 멤버 관리 화면에서 사용.
  Stream<List<Membership>> watchGroupMembers(String groupId) => _memberships
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((q) => q.docs.map(Membership.fromDoc).toList());

  /// 한 그룹의 승인 대기(PENDING) 멤버.
  Stream<List<Membership>> watchPendingMembers(String groupId) => _memberships
      .where('groupId', isEqualTo: groupId)
      .where('status', isEqualTo: MembershipStatus.pending.wire)
      .snapshots()
      .map((q) => q.docs.map(Membership.fromDoc).toList());
}
