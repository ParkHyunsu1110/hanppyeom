import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/group_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late GroupRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    // 결정적 초대 코드 생성을 위해 시드 고정.
    repo = GroupRepository(firestore: fs, random: Random(42));
  });

  Child sampleChild() => Child(
    id: '',
    name: '도윤',
    birthDate: DateTime(2024, 3, 15),
    sex: Sex.male,
  );

  test('createChildWithGroup은 child/group/멤버십/inviteCode를 원자적으로 만든다', () async {
    final groupId = await repo.createChildWithGroup(
      founderUid: 'u1',
      child: sampleChild(),
      relationLabel: '아빠',
    );

    // child id == group id 규약
    final childSnap = await fs.collection('children').doc(groupId).get();
    expect(childSnap.exists, isTrue);
    expect(childSnap.data()!['name'], '도윤');

    final groupSnap = await fs.collection('groups').doc(groupId).get();
    expect(groupSnap.data()!['childId'], groupId);
    final code = groupSnap.data()!['inviteCode'] as String;
    expect(code.length, 6);

    final membership = Membership.fromDoc(
      await fs
          .collection('memberships')
          .doc(Membership.docId(groupId, 'u1'))
          .get(),
    );
    expect(membership.role, MemberRole.parent);
    expect(membership.status, MembershipStatus.active);
    expect(membership.isAdmin, isTrue);
    expect(membership.relationLabel, '아빠');

    final codeSnap = await fs.collection('inviteCodes').doc(code).get();
    expect(codeSnap.data()!['groupId'], groupId);
  });

  test('regenerateInviteCode는 매핑을 교체하고 그룹 코드를 갱신한다', () async {
    final groupId = await repo.createChildWithGroup(
      founderUid: 'u1',
      child: sampleChild(),
    );
    final oldCode =
        (await fs.collection('groups').doc(groupId).get()).data()!['inviteCode']
            as String;

    final newCode = await repo.regenerateInviteCode(groupId);

    expect(newCode, isNot(oldCode));
    expect(
      (await fs.collection('inviteCodes').doc(oldCode).get()).exists,
      isFalse,
    );
    expect(
      (await fs.collection('inviteCodes').doc(newCode).get())
          .data()!['groupId'],
      groupId,
    );
    expect(
      (await fs.collection('groups').doc(groupId).get()).data()!['inviteCode'],
      newCode,
    );
  });
}
