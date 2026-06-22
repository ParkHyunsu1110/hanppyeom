import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child.dart';
import '../models/family_group.dart';
import '../models/membership.dart';

/// 아이([Child]) + 그룹([FamilyGroup]) + 창립 멤버십([Membership]) 생성/조회.
///
/// 규약: **그룹 문서 ID == 아이 문서 ID**(아이 1명당 그룹 1개). 보안 규칙이
/// 이 규약을 전제로 children 접근을 게이트한다. 코드→그룹 매핑은
/// `inviteCodes/{code}` 컬렉션으로 분리(비멤버 조회용).
class GroupRepository {
  GroupRepository({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final Random _random;

  // 혼동되는 글자(I, O, 0, 1) 제외.
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 6;

  CollectionReference<Map<String, dynamic>> get _children =>
      _firestore.collection('children');
  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _memberships =>
      _firestore.collection('memberships');
  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('inviteCodes');

  String _generateInviteCode() => List.generate(
    _codeLength,
    (_) => _codeChars[_random.nextInt(_codeChars.length)],
  ).join();

  /// 부모가 새 아이를 등록한다. child/group/창립 멤버십/inviteCode 를 한 배치로
  /// 원자적으로 생성하고 생성된 groupId(=childId)를 반환한다.
  ///
  /// [child]의 id는 무시된다(여기서 새 ID를 할당).
  Future<String> createChildWithGroup({
    required String founderUid,
    required Child child,
    String? relationLabel,
  }) async {
    final groupRef = _groups.doc(); // 자동 ID
    final groupId = groupRef.id;
    final code = _generateInviteCode();
    final membershipId = Membership.docId(groupId, founderUid);

    final founder = Membership(
      id: membershipId,
      userId: founderUid,
      groupId: groupId,
      role: MemberRole.parent,
      isAdmin: true,
      status: MembershipStatus.active,
      relationLabel: relationLabel,
    );
    final group = FamilyGroup(id: groupId, childId: groupId, inviteCode: code);

    final batch = _firestore.batch()
      ..set(_children.doc(groupId), child.toMap()) // 규약: childId == groupId
      ..set(groupRef, group.toMap())
      ..set(_memberships.doc(membershipId), founder.toMap())
      ..set(_inviteCodes.doc(code), {'groupId': groupId});
    await batch.commit();

    return groupId;
  }

  /// 초대 코드를 재발급한다(관리자). 기존 코드 매핑을 지우고 새 코드를 만든 뒤
  /// 그룹 문서의 inviteCode 를 갱신한다. 새 코드를 반환한다.
  Future<String> regenerateInviteCode(String groupId) async {
    final snap = await _groups.doc(groupId).get();
    final group = FamilyGroup.fromDoc(snap);
    final newCode = _generateInviteCode();

    final batch = _firestore.batch()
      ..delete(_inviteCodes.doc(group.inviteCode))
      ..set(_inviteCodes.doc(newCode), {'groupId': groupId})
      ..update(_groups.doc(groupId), {'inviteCode': newCode});
    await batch.commit();

    return newCode;
  }

  Future<FamilyGroup?> getGroup(String groupId) async {
    final snap = await _groups.doc(groupId).get();
    if (!snap.exists) return null;
    return FamilyGroup.fromDoc(snap);
  }

  Stream<FamilyGroup?> watchGroup(String groupId) => _groups
      .doc(groupId)
      .snapshots()
      .map((snap) => snap.exists ? FamilyGroup.fromDoc(snap) : null);

  /// 그룹 ID == 아이 ID 규약을 이용해 아이를 조회한다.
  Future<Child?> getChild(String groupId) async {
    final snap = await _children.doc(groupId).get();
    if (!snap.exists) return null;
    return Child.fromDoc(snap);
  }

  Stream<Child?> watchChild(String groupId) => _children
      .doc(groupId)
      .snapshots()
      .map((snap) => snap.exists ? Child.fromDoc(snap) : null);
}
