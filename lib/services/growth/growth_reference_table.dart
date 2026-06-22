import '../../models/child.dart' show Sex;
import '../../models/growth_record.dart' show GrowthType;
import '../../models/growth_reference.dart';

/// 성장도표 LMS 기준표(번들 / 읽기 전용). 실제 표는 후속 데이터 작업에서
/// `assets/growth/*.json`을 로드해 채운다. 기본은 비어 있고, 비어 있으면
/// 백분위 계산은 생략한다(추세선만 표시).
class GrowthReferenceTable {
  const GrowthReferenceTable(this._entries);

  const GrowthReferenceTable.empty() : _entries = const [];

  factory GrowthReferenceTable.fromJsonList(List<dynamic> jsonList) {
    return GrowthReferenceTable(
      jsonList
          .map((e) => GrowthReference.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<GrowthReference> _entries;

  bool get isEmpty => _entries.isEmpty;

  /// (sex, type)에서 ageMonths에 가장 가까운 기준값. 없으면 null.
  GrowthReference? lookup({
    required Sex sex,
    required GrowthType type,
    required int ageMonths,
  }) {
    GrowthReference? best;
    var bestDiff = 1 << 30;
    for (final e in _entries) {
      if (e.sex != sex || e.type != type) continue;
      final diff = (e.ageMonths - ageMonths).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = e;
      }
    }
    return best;
  }
}
