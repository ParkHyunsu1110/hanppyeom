import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feeding_record.dart';

/// 수유 기록 추가/조회. 권한(멤버 읽기/부모 쓰기)은 Firestore 규칙이 강제한다.
class FeedingRepository {
  FeedingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('feedingRecords');

  Future<String> addRecord({
    required String groupId,
    required DateTime fedAt,
    required FeedingKind kind,
    int? amountMl,
    String? memo,
    required String recordedBy,
  }) async {
    final ref = _records.doc();
    final record = FeedingRecord(
      id: ref.id,
      groupId: groupId,
      fedAt: fedAt,
      kind: kind,
      amountMl: amountMl,
      memo: memo,
      recordedBy: recordedBy,
    );
    await ref.set(record.toMap());
    return ref.id;
  }

  /// 기존 기록의 변경 가능한 필드만 갱신한다. groupId·recordedBy 등 불변 필드는
  /// 건드리지 않는다(Firestore 규칙: 부모만, groupId 불변).
  Future<void> updateRecord({
    required String recordId,
    required DateTime fedAt,
    required FeedingKind kind,
    int? amountMl,
    String? memo,
  }) => _records.doc(recordId).update({
    'fedAt': Timestamp.fromDate(fedAt),
    'kind': kind.wire,
    'amountMl': amountMl,
    'memo': memo,
  });

  Future<void> deleteRecord(String recordId) => _records.doc(recordId).delete();

  /// 수유 시각 내림차순(최근 우선) 구독.
  Stream<List<FeedingRecord>> watchRecords(String groupId) => _records
      .where('groupId', isEqualTo: groupId)
      .orderBy('fedAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(FeedingRecord.fromDoc).toList());
}
