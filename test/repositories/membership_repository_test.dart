import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/group_repository.dart';
import 'package:hanppyeom/repositories/membership_repository.dart';
import 'package:hanppyeom/repositories/repository_exceptions.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late GroupRepository groups;
  late MembershipRepository memberships;

  setUp(() {
    fs = FakeFirebaseFirestore();
    groups = GroupRepository(firestore: fs, random: Random(7));
    memberships = MembershipRepository(firestore: fs);
  });

  Future<({String groupId, String code})> seedGroup() async {
    final groupId = await groups.createChildWithGroup(
      founderUid: 'parent',
      child: Child(
        id: '',
        name: '도윤',
        birthDate: DateTime(2024, 1, 1),
        sex: Sex.male,
      ),
    );
    final code =
        (await fs.collection('groups').doc(groupId).get()).data()!['inviteCode']
            as String;
    return (groupId: groupId, code: code);
  }

  test('joinByInviteCode는 RELATIVE·PENDING 멤버십을 만든다', () async {
    final g = await seedGroup();

    await memberships.joinByInviteCode(
      uid: 'aunt',
      code: g.code,
      relationType: RelationType.imo,
    );

    final m = Membership.fromDoc(
      await fs
          .collection('memberships')
          .doc(Membership.docId(g.groupId, 'aunt'))
          .get(),
    );
    expect(m.role, MemberRole.relative);
    expect(m.status, MembershipStatus.pending);
    expect(m.isAdmin, isFalse);
    expect(m.relationType, RelationType.imo);
    expect(m.relationLabel, isNull);
  });

  test('joinByInviteCode ETC는 customLabel을 relationLabel에 담는다', () async {
    final g = await seedGroup();

    await memberships.joinByInviteCode(
      uid: 'aunt',
      code: g.code,
      relationType: RelationType.etc,
      customLabel: '큰이모',
    );

    final m = Membership.fromDoc(
      await fs
          .collection('memberships')
          .doc(Membership.docId(g.groupId, 'aunt'))
          .get(),
    );
    expect(m.relationType, RelationType.etc);
    expect(m.relationLabel, '큰이모');
  });

  test('코드는 대소문자/공백을 정규화한다', () async {
    final g = await seedGroup();

    await memberships.joinByInviteCode(
      uid: 'aunt',
      code: '  ${g.code.toLowerCase()}  ',
    );

    expect(
      (await fs
              .collection('memberships')
              .doc(Membership.docId(g.groupId, 'aunt'))
              .get())
          .exists,
      isTrue,
    );
  });

  test('잘못된 코드는 InviteCodeNotFoundException', () async {
    await seedGroup();
    expect(
      () => memberships.joinByInviteCode(uid: 'aunt', code: 'ZZZZZZ'),
      throwsA(isA<InviteCodeNotFoundException>()),
    );
  });

  test('중복 참여는 AlreadyJoinedException', () async {
    final g = await seedGroup();
    await memberships.joinByInviteCode(uid: 'aunt', code: g.code);

    expect(
      () => memberships.joinByInviteCode(uid: 'aunt', code: g.code),
      throwsA(isA<AlreadyJoinedException>()),
    );
  });

  test('approve는 PENDING을 ACTIVE로 전이한다', () async {
    final g = await seedGroup();
    await memberships.joinByInviteCode(uid: 'aunt', code: g.code);
    final membershipId = Membership.docId(g.groupId, 'aunt');

    await memberships.approve(membershipId);

    final m = Membership.fromDoc(
      await fs.collection('memberships').doc(membershipId).get(),
    );
    expect(m.status, MembershipStatus.active);
  });
}
