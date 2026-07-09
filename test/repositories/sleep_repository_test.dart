import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/sleep_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late SleepRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = SleepRepository(firestore: fs);
  });

  test('SleepRecord 직렬화 라운드트립 + duration', () async {
    final rec = SleepRecord(
      id: 's1',
      childId: 'g1',
      groupId: 'g1',
      startAt: DateTime(2026, 1, 1, 22),
      endAt: DateTime(2026, 1, 2, 6),
      kind: SleepKind.night,
      recordedBy: 'u1',
    );
    await fs.doc('sleepRecords/s1').set(rec.toMap());
    final back = SleepRecord.fromDoc(await fs.doc('sleepRecords/s1').get());

    expect(back.kind, SleepKind.night);
    expect(back.groupId, 'g1');
    expect(back.duration, const Duration(hours: 8));
    expect(rec.toMap()['kind'], 'NIGHT');
  });

  test('addRecord 저장 + watchRecords 최근 우선 정렬', () async {
    await repo.addRecord(
      groupId: 'g1',
      startAt: DateTime(2026, 1, 1, 13),
      endAt: DateTime(2026, 1, 1, 14),
      kind: SleepKind.nap,
      recordedBy: 'u1',
    );
    await repo.addRecord(
      groupId: 'g1',
      startAt: DateTime(2026, 1, 3, 22),
      endAt: DateTime(2026, 1, 4, 6),
      kind: SleepKind.night,
      recordedBy: 'u1',
    );

    final list = await repo.watchRecords('g1').first;
    expect(list.length, 2);
    expect(list.first.kind, SleepKind.night); // 1/3이 최근 → 먼저
    expect(list.last.kind, SleepKind.nap);
  });

  test('SleepKind.fromWire 폴백', () {
    expect(SleepKind.fromWire('NIGHT'), SleepKind.night);
    expect(SleepKind.fromWire('X'), SleepKind.nap);
  });

  test('updateRecord는 시작/종료/종류만 바꾸고 groupId 등 불변 필드는 유지한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      startAt: DateTime(2026, 1, 1, 13),
      endAt: DateTime(2026, 1, 1, 14),
      kind: SleepKind.nap,
      recordedBy: 'u1',
    );

    await repo.updateRecord(
      recordId: id,
      startAt: DateTime(2026, 1, 1, 22),
      endAt: DateTime(2026, 1, 2, 6),
      kind: SleepKind.night,
    );

    final snap = await fs.collection('sleepRecords').doc(id).get();
    expect(snap.data()!['kind'], 'NIGHT');
    expect(
      (snap.data()!['startAt'] as Timestamp).toDate(),
      DateTime(2026, 1, 1, 22),
    );
    expect(
      (snap.data()!['endAt'] as Timestamp).toDate(),
      DateTime(2026, 1, 2, 6),
    );
    // 규칙(groupId 불변)·규약 필드는 그대로여야 한다.
    expect(snap.data()!['groupId'], 'g1');
    expect(snap.data()!['childId'], 'g1');
    expect(snap.data()!['recordedBy'], 'u1');
  });

  test('deleteRecord는 문서를 제거한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      startAt: DateTime(2026, 1, 1, 13),
      endAt: DateTime(2026, 1, 1, 14),
      kind: SleepKind.nap,
      recordedBy: 'u1',
    );

    await repo.deleteRecord(id);

    final snap = await fs.collection('sleepRecords').doc(id).get();
    expect(snap.exists, isFalse);
  });
}
