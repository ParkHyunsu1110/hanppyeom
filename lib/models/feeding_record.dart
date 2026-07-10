import 'package:cloud_firestore/cloud_firestore.dart';

/// 수유 종류. Firestore에는 wire 값으로 저장하고, UI에는 [label]을 쓴다.
enum FeedingKind {
  breast('BREAST', '모유'),
  formula('FORMULA', '분유'),
  solid('SOLID', '이유식');

  const FeedingKind(this.wire, this.label);
  final String wire;
  final String label;

  static FeedingKind fromWire(String? value) {
    for (final k in FeedingKind.values) {
      if (k.wire == value) return k;
    }
    return FeedingKind.breast;
  }
}

/// 한 번의 수유 기록. Firestore `feedingRecords/{id}` 문서.
/// 규칙 검증용으로 [groupId] 비정규화(규약상 childId == groupId).
class FeedingRecord {
  const FeedingRecord({
    required this.id,
    required this.groupId,
    required this.fedAt,
    required this.kind,
    this.amountMl,
    this.memo,
    required this.recordedBy,
  });

  final String id;
  final String groupId;
  final DateTime fedAt;
  final FeedingKind kind;

  /// 수유량(ml). 모유 등 양을 모르면 null.
  final int? amountMl;

  /// 자유 메모. 없으면 null.
  final String? memo;
  final String recordedBy;

  factory FeedingRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FeedingRecord(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      fedAt:
          (data['fedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: FeedingKind.fromWire(data['kind'] as String?),
      amountMl: (data['amountMl'] as num?)?.toInt(),
      memo: data['memo'] as String?,
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'groupId': groupId,
    'fedAt': Timestamp.fromDate(fedAt),
    'kind': kind.wire,
    'amountMl': amountMl,
    'memo': memo,
    'recordedBy': recordedBy,
  };
}
