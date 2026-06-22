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

    // 6개 유형×성별이 0~60개월 전 구간 존재(0/12/60개월 표본 확인)
    for (final sex in Sex.values) {
      for (final type in GrowthType.values) {
        for (final age in [0, 12, 60]) {
          expect(
            table.lookup(sex: sex, type: type, ageMonths: age),
            isNotNull,
            reason: '$sex $type $age개월 누락',
          );
        }
      }
    }

    // 5세(60개월) 키 앵커 — WHO 값.
    final h60 = table.lookup(
      sex: Sex.male,
      type: GrowthType.height,
      ageMonths: 60,
    );
    expect(h60!.m, closeTo(109.9638, 1e-4));

    // 5세 초과(학령기) 확장 — CDC 2-20세. 키/체중 10세·18세 존재.
    expect(
      table.lookup(sex: Sex.male, type: GrowthType.height, ageMonths: 120),
      isNotNull,
    );
    expect(
      table.lookup(sex: Sex.female, type: GrowthType.weight, ageMonths: 216),
      isNotNull,
    );
    // 키 10세 중앙값(약 138.8cm) 합리성.
    final h120 = table.lookup(
      sex: Sex.male,
      type: GrowthType.height,
      ageMonths: 120,
    )!;
    expect(h120.m, greaterThan(125));
    expect(h120.m, lessThan(150));
  });
}
