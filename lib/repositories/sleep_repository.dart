import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sleep_record.dart';

/// 수면 기록 추가/조회. 권한(멤버 읽기/부모 쓰기)은 Firestore 규칙이 강제한다.
class SleepRepository {
  SleepRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('sleepRecords');

  Future<String> addRecord({
    required String groupId,
    required DateTime startAt,
    required DateTime endAt,
    required SleepKind kind,
    required String recordedBy,
  }) async {
    final ref = _records.doc();
    final record = SleepRecord(
      id: ref.id,
      childId: groupId,
      groupId: groupId,
      startAt: startAt,
      endAt: endAt,
      kind: kind,
      recordedBy: recordedBy,
    );
    await ref.set(record.toMap());
    return ref.id;
  }

  /// 기존 기록의 시작/종료/종류만 갱신한다. groupId 등 불변 필드는 건드리지 않는다
  /// (Firestore 규칙: 부모만, groupId 불변).
  Future<void> updateRecord({
    required String recordId,
    required DateTime startAt,
    required DateTime endAt,
    required SleepKind kind,
  }) => _records.doc(recordId).update({
    'startAt': Timestamp.fromDate(startAt),
    'endAt': Timestamp.fromDate(endAt),
    'kind': kind.wire,
  });

  Future<void> deleteRecord(String recordId) => _records.doc(recordId).delete();

  /// 시작 시각 내림차순(최근 우선) 구독.
  Stream<List<SleepRecord>> watchRecords(String groupId) => _records
      .where('groupId', isEqualTo: groupId)
      .orderBy('startAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(SleepRecord.fromDoc).toList());
}
