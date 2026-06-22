import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/services/growth/growth_reference_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('번들된 WHO 에셋이 로드되고 앵커값이 맞다', () async {
    final table = await GrowthReferenceTable.loadAsset(
      'assets/growth/who_lms.json',
    );
    expect(table.isEmpty, isFalse);

    // 남아 체중 0개월 — 알려진 WHO 값.
    final ref = table.lookup(
      sex: Sex.male,
      type: GrowthType.weight,
      ageMonths: 0,
    );
    expect(ref, isNotNull);
    expect(ref!.m, closeTo(3.3464, 1e-6));
    expect(ref.l, closeTo(0.3487, 1e-6));
    expect(ref.s, closeTo(0.14602, 1e-6));

    // 6개 유형×성별 모두 존재(키/체중/머리둘레 × 남/녀)
    for (final sex in Sex.values) {
      for (final type in GrowthType.values) {
        expect(
          table.lookup(sex: sex, type: type, ageMonths: 12),
          isNotNull,
          reason: '$sex $type 12개월 누락',
        );
      }
    }
  });
}
