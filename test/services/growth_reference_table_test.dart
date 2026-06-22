import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/services/growth/growth_reference_table.dart';
import 'package:hanppyeom/services/growth/lms_percentile.dart';

void main() {
  // 실제 WHO 값(남아 체중 0개월).
  final table = GrowthReferenceTable.fromJsonList([
    {
      'sex': 'M',
      'type': 'WEIGHT',
      'ageMonths': 0,
      'l': 0.3487,
      'm': 3.3464,
      's': 0.14602,
    },
    {
      'sex': 'M',
      'type': 'WEIGHT',
      'ageMonths': 1,
      'l': 0.2297,
      'm': 4.4709,
      's': 0.13395,
    },
    {
      'sex': 'F',
      'type': 'WEIGHT',
      'ageMonths': 0,
      'l': 0.3809,
      'm': 3.2322,
      's': 0.14171,
    },
  ]);

  test('lookup은 정확 개월을 찾는다', () {
    final ref = table.lookup(
      sex: Sex.male,
      type: GrowthType.weight,
      ageMonths: 1,
    );
    expect(ref, isNotNull);
    expect(ref!.m, 4.4709);
  });

  test('lookup은 없는 개월에 가장 가까운 값을 반환한다', () {
    final ref = table.lookup(
      sex: Sex.male,
      type: GrowthType.weight,
      ageMonths: 5,
    );
    expect(ref, isNotNull);
    expect(ref!.ageMonths, 1); // 0,1 중 5에 가까운 1
  });

  test('성별/유형이 다르면 매칭 안 됨', () {
    expect(
      table.lookup(sex: Sex.male, type: GrowthType.height, ageMonths: 0),
      isNull,
    );
  });

  test('중앙값(M) 측정은 50번째 백분위', () {
    final ref = table.lookup(
      sex: Sex.male,
      type: GrowthType.weight,
      ageMonths: 0,
    )!;
    expect(percentileFor(ref, ref.m), closeTo(50, 0.01));
  });

  test('중앙값보다 무거우면 50%보다 높다', () {
    final ref = table.lookup(
      sex: Sex.male,
      type: GrowthType.weight,
      ageMonths: 0,
    )!;
    expect(percentileFor(ref, 4.0), greaterThan(50));
  });

  test('빈 표는 isEmpty', () {
    expect(const GrowthReferenceTable.empty().isEmpty, isTrue);
    expect(table.isEmpty, isFalse);
  });
}
