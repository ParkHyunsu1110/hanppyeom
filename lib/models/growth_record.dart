import 'package:cloud_firestore/cloud_firestore.dart';

/// 성장기록 측정 유형. Firestore에는 wire 값으로 저장한다.
enum GrowthType {
  height('HEIGHT'),
  weight('WEIGHT'),
  head('HEAD');

  const GrowthType(this.wire);
  final String wire;

  static GrowthType? fromWire(String? value) {
    for (final t in GrowthType.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// 한 번의 성장 측정. Firestore `growthRecords/{id}` 문서.
///
/// 규칙 검증을 위해 [groupId]를 비정규화해 들고 있는다(child→group 조인 회피).
/// 규약상 childId == groupId.
class GrowthRecord {
  const GrowthRecord({
    required this.id,
    required this.childId,
    required this.groupId,
    required this.date,
    required this.type,
    required this.value,
    required this.recordedBy,
  });

  /// 문서 ID(본문에는 저장하지 않음).
  final String id;
  final String childId;
  final String groupId;
  final DateTime date;
  final GrowthType type;

  /// 측정값. 키/머리둘레는 cm, 체중은 kg.
  final double value;

  /// 기록한 사용자 uid.
  final String recordedBy;

  factory GrowthRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return GrowthRecord(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      date:
          (data['date'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: GrowthType.fromWire(data['type'] as String?) ?? GrowthType.height,
      value: (data['value'] as num?)?.toDouble() ?? 0,
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'childId': childId,
    'groupId': groupId,
    'date': Timestamp.fromDate(date),
    'type': type.wire,
    'value': value,
    'recordedBy': recordedBy,
  };
}
