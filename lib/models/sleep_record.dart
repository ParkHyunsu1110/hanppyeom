import 'package:cloud_firestore/cloud_firestore.dart';

/// 수면 종류. Firestore에는 wire 값으로 저장한다.
enum SleepKind {
  night('NIGHT'),
  nap('NAP');

  const SleepKind(this.wire);
  final String wire;

  static SleepKind fromWire(String? value) {
    for (final k in SleepKind.values) {
      if (k.wire == value) return k;
    }
    return SleepKind.nap;
  }
}

/// 한 번의 수면 기록. Firestore `sleepRecords/{id}` 문서.
/// 규칙 검증용으로 [groupId] 비정규화(규약상 childId == groupId).
class SleepRecord {
  const SleepRecord({
    required this.id,
    required this.childId,
    required this.groupId,
    required this.startAt,
    required this.endAt,
    required this.kind,
    required this.recordedBy,
  });

  final String id;
  final String childId;
  final String groupId;
  final DateTime startAt;
  final DateTime endAt;
  final SleepKind kind;
  final String recordedBy;

  /// 수면 길이.
  Duration get duration => endAt.difference(startAt);

  factory SleepRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SleepRecord(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      startAt:
          (data['startAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt:
          (data['endAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: SleepKind.fromWire(data['kind'] as String?),
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'childId': childId,
    'groupId': groupId,
    'startAt': Timestamp.fromDate(startAt),
    'endAt': Timestamp.fromDate(endAt),
    'kind': kind.wire,
    'recordedBy': recordedBy,
  };
}
