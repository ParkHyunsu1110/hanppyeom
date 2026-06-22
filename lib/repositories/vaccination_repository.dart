import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vaccination.dart';

/// 접종 완료 기록 추가/삭제/조회. 권한(멤버 읽기/부모 쓰기)은 규칙이 강제한다.
class VaccinationRepository {
  VaccinationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('vaccinations');

  /// 차수를 완료 처리(멱등 — 결정적 문서 ID).
  Future<void> markDone({
    required String groupId,
    required String vaccineCode,
    required int doseNumber,
    required DateTime completedDate,
    required String recordedBy,
  }) {
    final id = Vaccination.docId(groupId, vaccineCode, doseNumber);
    final record = Vaccination(
      id: id,
      childId: groupId,
      groupId: groupId,
      vaccineCode: vaccineCode,
      doseNumber: doseNumber,
      completedDate: completedDate,
      recordedBy: recordedBy,
    );
    return _records.doc(id).set(record.toMap());
  }

  Future<void> markUndone({
    required String groupId,
    required String vaccineCode,
    required int doseNumber,
  }) => _records
      .doc(Vaccination.docId(groupId, vaccineCode, doseNumber))
      .delete();

  Stream<List<Vaccination>> watchCompletions(String groupId) => _records
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((q) => q.docs.map(Vaccination.fromDoc).toList());
}
