import 'package:cloud_firestore/cloud_firestore.dart';

/// 표준 접종 일정의 한 항목(번들 참조 데이터, 사용자 데이터 아님).
class VaccineScheduleItem {
  const VaccineScheduleItem({
    required this.code,
    required this.name,
    required this.doseNumber,
    required this.ageMonths,
  });

  final String code;
  final String name;
  final int doseNumber;

  /// 권장 접종 시작 개월수.
  final int ageMonths;

  /// 접종(코드+차수) 식별 키.
  String get key => '${code}_$doseNumber';

  factory VaccineScheduleItem.fromJson(Map<String, dynamic> json) {
    return VaccineScheduleItem(
      code: json['code'] as String,
      name: json['name'] as String,
      doseNumber: (json['doseNumber'] as num).toInt(),
      ageMonths: (json['ageMonths'] as num).toInt(),
    );
  }
}

/// 아이의 접종 완료 기록. Firestore `vaccinations/{groupId}_{code}_{dose}`.
/// 문서가 존재하면 해당 차수 완료(DONE), 없으면 미접종.
class Vaccination {
  const Vaccination({
    required this.id,
    required this.childId,
    required this.groupId,
    required this.vaccineCode,
    required this.doseNumber,
    required this.completedDate,
    required this.recordedBy,
  });

  final String id;
  final String childId;
  final String groupId;
  final String vaccineCode;
  final int doseNumber;
  final DateTime completedDate;
  final String recordedBy;

  String get key => '${vaccineCode}_$doseNumber';

  static String docId(String groupId, String code, int dose) =>
      '${groupId}_${code}_$dose';

  factory Vaccination.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Vaccination(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      vaccineCode: data['vaccineCode'] as String? ?? '',
      doseNumber: (data['doseNumber'] as num?)?.toInt() ?? 0,
      completedDate:
          (data['completedDate'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'childId': childId,
    'groupId': groupId,
    'vaccineCode': vaccineCode,
    'doseNumber': doseNumber,
    'completedDate': Timestamp.fromDate(completedDate),
    'status': 'DONE',
    'recordedBy': recordedBy,
  };
}
