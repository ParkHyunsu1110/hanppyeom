import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';

void main() {
  late FakeFirebaseFirestore fs;

  setUp(() => fs = FakeFirebaseFirestore());

  Future<DocumentSnapshot<Map<String, dynamic>>> roundTrip(
    String path,
    Map<String, dynamic> data,
  ) async {
    await fs.doc(path).set(data);
    return fs.doc(path).get();
  }

  group('AppUser', () {
    test('toMap/fromDoc 라운드트립', () async {
      const user = AppUser(
        id: 'u1',
        email: 'a@b.com',
        displayName: '현수',
        photoUrl: 'http://x/y.png',
      );
      final back = AppUser.fromDoc(await roundTrip('users/u1', user.toMap()));

      expect(back.id, 'u1');
      expect(back.email, 'a@b.com');
      expect(back.displayName, '현수');
      expect(back.photoUrl, 'http://x/y.png');
    });

    test('toMap은 id를 본문에 넣지 않는다', () {
      const user = AppUser(id: 'u1', email: 'a@b.com', displayName: '현수');
      expect(user.toMap().containsKey('id'), isFalse);
    });
  });

  group('Child', () {
    test('toMap/fromDoc 라운드트립 (birthDate/sex 포함)', () async {
      final child = Child(
        id: 'c1',
        name: '도윤',
        birthDate: DateTime(2024, 3, 15),
        sex: Sex.male,
        bloodType: 'A',
        rrnEncrypted: 'enc',
        notes: '특이사항',
      );
      final back = Child.fromDoc(await roundTrip('children/c1', child.toMap()));

      expect(back.name, '도윤');
      expect(back.birthDate, DateTime(2024, 3, 15));
      expect(back.sex, Sex.male);
      expect(back.bloodType, 'A');
      expect(back.rrnEncrypted, 'enc');
      expect(back.notes, '특이사항');
    });

    test('photoUrl 라운드트립', () async {
      final child = Child(
        id: 'c1',
        name: '도윤',
        birthDate: DateTime(2024, 3, 15),
        sex: Sex.male,
        photoUrl: 'https://example.com/p.jpg',
      );
      final back = Child.fromDoc(await roundTrip('children/c1', child.toMap()));

      expect(back.photoUrl, 'https://example.com/p.jpg');
      expect(child.copyWith(photoUrl: 'x').photoUrl, 'x');
      expect(child.copyWith().photoUrl, 'https://example.com/p.jpg');
    });

    test('birthDate는 Timestamp로 저장된다', () {
      final child = Child(
        id: 'c1',
        name: '도윤',
        birthDate: DateTime(2024, 3, 15),
        sex: Sex.female,
      );
      expect(child.toMap()['birthDate'], isA<Timestamp>());
      expect(child.toMap()['sex'], 'F');
    });
  });

  group('FamilyGroup', () {
    test('toMap/fromDoc 라운드트립', () async {
      const group = FamilyGroup(id: 'g1', childId: 'g1', inviteCode: 'ABC123');
      final back = FamilyGroup.fromDoc(
        await roundTrip('groups/g1', group.toMap()),
      );

      expect(back.id, 'g1');
      expect(back.childId, 'g1');
      expect(back.inviteCode, 'ABC123');
    });
  });

  group('Membership', () {
    test('docId 규약', () {
      expect(Membership.docId('g1', 'u1'), 'g1_u1');
    });

    test('toMap/fromDoc 라운드트립 (enum wire 포함)', () async {
      final membership = Membership(
        id: Membership.docId('g1', 'u1'),
        userId: 'u1',
        groupId: 'g1',
        role: MemberRole.parent,
        relationLabel: '아빠',
        isAdmin: true,
        status: MembershipStatus.active,
      );
      expect(membership.toMap()['role'], 'PARENT');
      expect(membership.toMap()['status'], 'ACTIVE');

      final back = Membership.fromDoc(
        await roundTrip('memberships/g1_u1', membership.toMap()),
      );
      expect(back.id, 'g1_u1');
      expect(back.userId, 'u1');
      expect(back.groupId, 'g1');
      expect(back.role, MemberRole.parent);
      expect(back.relationLabel, '아빠');
      expect(back.isAdmin, isTrue);
      expect(back.status, MembershipStatus.active);
    });

    test('relationType 라운드트립 (호칭은 권한과 분리)', () async {
      final membership = Membership(
        id: Membership.docId('g1', 'u2'),
        userId: 'u2',
        groupId: 'g1',
        role: MemberRole.relative,
        relationType: RelationType.imo,
        isAdmin: false,
        status: MembershipStatus.active,
      );
      expect(membership.toMap()['relationType'], 'IMO');

      final back = Membership.fromDoc(
        await roundTrip('memberships/g1_u2', membership.toMap()),
      );
      expect(back.relationType, RelationType.imo);
      expect(back.relationLabel, isNull);
    });

    test('ETC는 customLabel(relationLabel)에 자유 입력을 담는다', () async {
      final membership = Membership(
        id: Membership.docId('g1', 'u3'),
        userId: 'u3',
        groupId: 'g1',
        role: MemberRole.relative,
        relationType: RelationType.etc,
        relationLabel: '큰이모',
        isAdmin: false,
        status: MembershipStatus.active,
      );
      final back = Membership.fromDoc(
        await roundTrip('memberships/g1_u3', membership.toMap()),
      );
      expect(back.relationType, RelationType.etc);
      expect(back.relationLabel, '큰이모');
    });

    test('구 데이터(relationType 없음)는 legacy relationLabel로 폴백한다', () async {
      // relationType 필드가 없는 구 문서.
      final back = Membership.fromDoc(
        await roundTrip('memberships/g1_u4', <String, dynamic>{
          'userId': 'u4',
          'groupId': 'g1',
          'role': 'RELATIVE',
          'relationLabel': '이모',
          'isAdmin': false,
          'status': 'ACTIVE',
        }),
      );
      expect(back.relationType, isNull);
      expect(back.relationLabel, '이모');
    });
  });

  group('enum 폴백', () {
    test('Sex.fromWire', () {
      expect(Sex.fromWire('M'), Sex.male);
      expect(Sex.fromWire('F'), Sex.female);
      expect(Sex.fromWire('X'), isNull);
      expect(Sex.fromWire(null), isNull);
    });

    test('MemberRole은 알 수 없는 값에서 최소권한(relative)으로 폴백', () {
      expect(MemberRole.fromWire('PARENT'), MemberRole.parent);
      expect(MemberRole.fromWire('RELATIVE'), MemberRole.relative);
      expect(MemberRole.fromWire('UNKNOWN'), MemberRole.relative);
      expect(MemberRole.fromWire(null), MemberRole.relative);
    });

    test('MembershipStatus는 알 수 없는 값에서 접근불가(pending)로 폴백', () {
      expect(MembershipStatus.fromWire('ACTIVE'), MembershipStatus.active);
      expect(MembershipStatus.fromWire('PENDING'), MembershipStatus.pending);
      expect(MembershipStatus.fromWire('UNKNOWN'), MembershipStatus.pending);
      expect(MembershipStatus.fromWire(null), MembershipStatus.pending);
    });

    test('RelationType은 알 수 없는/없는 값에서 null로 폴백', () {
      expect(RelationType.fromWire('IMO'), RelationType.imo);
      expect(RelationType.fromWire('ETC'), RelationType.etc);
      expect(RelationType.fromWire('UNKNOWN'), isNull);
      expect(RelationType.fromWire(null), isNull);
    });
  });
}
