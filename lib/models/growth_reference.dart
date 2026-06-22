import 'child.dart' show Sex;
import 'growth_record.dart' show GrowthType;

/// 성장도표 LMS 기준값(사용자 데이터 아님, 앱 번들 / 읽기 전용).
///
/// 출처: 질병관리청 2017 소아청소년 성장도표(0–35개월 WHO 기반) — 공공데이터포털
/// "영유아성장도표 LMS기준". 2027 개정 예정이므로 교체 가능한 구조로 둔다.
class GrowthReference {
  const GrowthReference({
    required this.sex,
    required this.type,
    required this.ageMonths,
    required this.l,
    required this.m,
    required this.s,
  });

  final Sex sex;
  final GrowthType type;
  final int ageMonths;

  /// Box-Cox 변환 모수.
  final double l;

  /// 중앙값(median).
  final double m;

  /// 변동계수(coefficient of variation).
  final double s;

  factory GrowthReference.fromJson(Map<String, dynamic> json) {
    return GrowthReference(
      sex: Sex.fromWire(json['sex'] as String?) ?? Sex.male,
      type: GrowthType.fromWire(json['type'] as String?) ?? GrowthType.height,
      ageMonths: (json['ageMonths'] as num).toInt(),
      l: (json['l'] as num).toDouble(),
      m: (json['m'] as num).toDouble(),
      s: (json['s'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sex': sex.wire,
    'type': type.wire,
    'ageMonths': ageMonths,
    'l': l,
    'm': m,
    's': s,
  };
}
