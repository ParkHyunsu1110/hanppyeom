import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/growth_record.dart';

/// 성장기록 추가/조회. 규약상 childId == groupId.
///
/// 권한(멤버 읽기/부모 쓰기)은 Firestore 규칙이 강제한다.
class GrowthRepository {
  GrowthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('growthRecords');

  /// 기록을 추가하고 생성된 문서 ID를 반환한다.
  Future<String> addRecord({
    required String groupId,
    required GrowthType type,
    required double value,
    required DateTime date,
    required String recordedBy,
  }) async {
    final ref = _records.doc();
    final record = GrowthRecord(
      id: ref.id,
      childId: groupId, // 규약: childId == groupId
      groupId: groupId,
      date: date,
      type: type,
      value: value,
      recordedBy: recordedBy,
    );
    await ref.set(record.toMap());
    return ref.id;
  }

  /// 기존 기록의 값/측정일만 갱신한다. groupId 등 불변 필드는 건드리지 않는다
  /// (Firestore 규칙: 부모만, groupId 불변).
  Future<void> updateRecord({
    required String recordId,
    required double value,
    required DateTime date,
  }) => _records.doc(recordId).update({
    'value': value,
    'date': Timestamp.fromDate(date),
  });

  Future<void> deleteRecord(String recordId) => _records.doc(recordId).delete();

  /// 한 아이의 특정 유형 기록을 측정일 오름차순으로 구독(그래프용).
  Stream<List<GrowthRecord>> watchRecords({
    required String groupId,
    required GrowthType type,
  }) => _records
      .where('groupId', isEqualTo: groupId)
      .where('type', isEqualTo: type.wire)
      .orderBy('date')
      .snapshots()
      .map((q) => q.docs.map(GrowthRecord.fromDoc).toList());
}
