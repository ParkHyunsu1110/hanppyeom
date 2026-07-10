import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/feeding_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late FeedingRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FeedingRepository(firestore: fs);
  });

  test('FeedingRecord 직렬화 라운드트립', () async {
    final rec = FeedingRecord(
      id: 'f1',
      groupId: 'g1',
      fedAt: DateTime(2026, 1, 1, 9, 30),
      kind: FeedingKind.formula,
      amountMl: 120,
      memo: '잘 먹음',
      recordedBy: 'u1',
    );
    await fs.doc('feedingRecords/f1').set(rec.toMap());
    final back = FeedingRecord.fromDoc(await fs.doc('feedingRecords/f1').get());

    expect(back.kind, FeedingKind.formula);
    expect(back.groupId, 'g1');
    expect(back.amountMl, 120);
    expect(back.memo, '잘 먹음');
    expect(back.recordedBy, 'u1');
    expect(rec.toMap()['kind'], 'FORMULA');
  });

  test('amountMl·memo가 없으면 null로 저장/복원된다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      fedAt: DateTime(2026, 1, 1, 7),
      kind: FeedingKind.breast,
      recordedBy: 'u1',
    );
    final back = FeedingRecord.fromDoc(
      await fs.collection('feedingRecords').doc(id).get(),
    );
    expect(back.amountMl, isNull);
    expect(back.memo, isNull);
    expect(back.kind, FeedingKind.breast);
  });

  test('addRecord 저장 + watchRecords 최근 우선 정렬', () async {
    await repo.addRecord(
      groupId: 'g1',
      fedAt: DateTime(2026, 1, 1, 8),
      kind: FeedingKind.breast,
      recordedBy: 'u1',
    );
    await repo.addRecord(
      groupId: 'g1',
      fedAt: DateTime(2026, 1, 3, 12),
      kind: FeedingKind.solid,
      amountMl: 80,
      recordedBy: 'u1',
    );

    final list = await repo.watchRecords('g1').first;
    expect(list.length, 2);
    expect(list.first.kind, FeedingKind.solid); // 1/3이 최근 → 먼저
    expect(list.last.kind, FeedingKind.breast);
  });

  test('FeedingKind.fromWire 폴백', () {
    expect(FeedingKind.fromWire('FORMULA'), FeedingKind.formula);
    expect(FeedingKind.fromWire('SOLID'), FeedingKind.solid);
    expect(FeedingKind.fromWire('X'), FeedingKind.breast);
  });

  test('updateRecord는 변경 필드만 바꾸고 groupId 등 불변 필드는 유지한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      fedAt: DateTime(2026, 1, 1, 8),
      kind: FeedingKind.breast,
      amountMl: 60,
      memo: '조금',
      recordedBy: 'u1',
    );

    await repo.updateRecord(
      recordId: id,
      fedAt: DateTime(2026, 1, 1, 12),
      kind: FeedingKind.formula,
      amountMl: 150,
      memo: '많이',
    );

    final snap = await fs.collection('feedingRecords').doc(id).get();
    expect(snap.data()!['kind'], 'FORMULA');
    expect(snap.data()!['amountMl'], 150);
    expect(snap.data()!['memo'], '많이');
    expect(
      (snap.data()!['fedAt'] as Timestamp).toDate(),
      DateTime(2026, 1, 1, 12),
    );
    // 규칙(groupId 불변)·규약 필드는 그대로여야 한다.
    expect(snap.data()!['groupId'], 'g1');
    expect(snap.data()!['recordedBy'], 'u1');
  });

  test('deleteRecord는 문서를 제거한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      fedAt: DateTime(2026, 1, 1, 8),
      kind: FeedingKind.breast,
      recordedBy: 'u1',
    );

    await repo.deleteRecord(id);

    final snap = await fs.collection('feedingRecords').doc(id).get();
    expect(snap.exists, isFalse);
  });
}
