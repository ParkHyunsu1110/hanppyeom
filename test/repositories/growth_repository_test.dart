import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/growth_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late GrowthRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = GrowthRepository(firestore: fs);
  });

  test('addRecord는 groupId/childId/유형/값을 저장한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      type: GrowthType.height,
      value: 75.2,
      date: DateTime(2026, 2, 1),
      recordedBy: 'u1',
    );

    final snap = await fs.collection('growthRecords').doc(id).get();
    expect(snap.data()!['groupId'], 'g1');
    expect(snap.data()!['childId'], 'g1'); // 규약: childId == groupId
    expect(snap.data()!['type'], 'HEIGHT');
    expect(snap.data()!['value'], 75.2);
    expect(snap.data()!['recordedBy'], 'u1');
  });

  test('watchRecords는 유형으로 필터하고 날짜 오름차순으로 정렬한다', () async {
    await repo.addRecord(
      groupId: 'g1',
      type: GrowthType.height,
      value: 80,
      date: DateTime(2026, 3, 1),
      recordedBy: 'u1',
    );
    await repo.addRecord(
      groupId: 'g1',
      type: GrowthType.height,
      value: 75,
      date: DateTime(2026, 1, 1),
      recordedBy: 'u1',
    );
    await repo.addRecord(
      groupId: 'g1',
      type: GrowthType.weight,
      value: 9,
      date: DateTime(2026, 2, 1),
      recordedBy: 'u1',
    );

    final heights = await repo
        .watchRecords(groupId: 'g1', type: GrowthType.height)
        .first;

    expect(heights.length, 2);
    expect(heights.first.value, 75); // 1월이 먼저
    expect(heights.last.value, 80); // 3월이 나중
    expect(heights.every((r) => r.type == GrowthType.height), isTrue);
  });

  test('updateRecord는 value/date만 바꾸고 groupId 등 불변 필드는 유지한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      type: GrowthType.height,
      value: 75.2,
      date: DateTime(2026, 2, 1),
      recordedBy: 'u1',
    );

    await repo.updateRecord(
      recordId: id,
      value: 80.5,
      date: DateTime(2026, 3, 1),
    );

    final snap = await fs.collection('growthRecords').doc(id).get();
    expect(snap.data()!['value'], 80.5);
    expect((snap.data()!['date'] as Timestamp).toDate(), DateTime(2026, 3, 1));
    // 규칙(groupId 불변)·규약 필드는 그대로여야 한다.
    expect(snap.data()!['groupId'], 'g1');
    expect(snap.data()!['childId'], 'g1');
    expect(snap.data()!['type'], 'HEIGHT');
    expect(snap.data()!['recordedBy'], 'u1');
  });

  test('deleteRecord는 문서를 제거한다', () async {
    final id = await repo.addRecord(
      groupId: 'g1',
      type: GrowthType.weight,
      value: 9,
      date: DateTime(2026, 2, 1),
      recordedBy: 'u1',
    );

    await repo.deleteRecord(id);

    final snap = await fs.collection('growthRecords').doc(id).get();
    expect(snap.exists, isFalse);
  });
}
