import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/vaccination_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late VaccinationRepository repo;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = VaccinationRepository(firestore: fs);
  });

  test('markDone은 결정적 ID로 완료 기록 생성(멱등)', () async {
    await repo.markDone(
      groupId: 'g1',
      vaccineCode: 'HepB',
      doseNumber: 1,
      completedDate: DateTime(2026, 1, 1),
      recordedBy: 'u1',
    );
    // 같은 차수 재호출 → 덮어쓰기(중복 없음)
    await repo.markDone(
      groupId: 'g1',
      vaccineCode: 'HepB',
      doseNumber: 1,
      completedDate: DateTime(2026, 1, 2),
      recordedBy: 'u1',
    );

    final list = await repo.watchCompletions('g1').first;
    expect(list.length, 1);
    expect(list.first.key, 'HepB_1');
    final doc = await fs
        .collection('vaccinations')
        .doc(Vaccination.docId('g1', 'HepB', 1))
        .get();
    expect(doc.data()!['status'], 'DONE');
  });

  test('markUndone은 완료 기록 삭제', () async {
    await repo.markDone(
      groupId: 'g1',
      vaccineCode: 'BCG',
      doseNumber: 1,
      completedDate: DateTime(2026, 1, 1),
      recordedBy: 'u1',
    );
    await repo.markUndone(groupId: 'g1', vaccineCode: 'BCG', doseNumber: 1);
    final list = await repo.watchCompletions('g1').first;
    expect(list, isEmpty);
  });
}
