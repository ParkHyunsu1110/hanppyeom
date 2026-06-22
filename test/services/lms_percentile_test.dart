import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/services/growth/lms_percentile.dart';

void main() {
  group('standardNormalCdf', () {
    test('Φ(0)=0.5, Φ(1)≈0.8413, Φ(-1)≈0.1587', () {
      expect(standardNormalCdf(0), closeTo(0.5, 1e-6));
      expect(standardNormalCdf(1), closeTo(0.8413, 1e-3));
      expect(standardNormalCdf(-1), closeTo(0.1587, 1e-3));
    });
  });

  group('lmsZScore', () {
    test('값=중앙값(M)이면 Z=0 (L≠0)', () {
      expect(lmsZScore(value: 10, l: 1, m: 10, s: 0.1), closeTo(0, 1e-9));
    });

    test('L=0 분기 (Z=ln(X/M)/S)', () {
      expect(lmsZScore(value: 10, l: 0, m: 10, s: 0.1), closeTo(0, 1e-9));
      expect(
        lmsZScore(value: 11, l: 0, m: 10, s: 0.1),
        closeTo(0.953101798 / 1, 1e-6),
      ); // ln(1.1)/0.1
    });

    test('잘못된 입력은 ArgumentError', () {
      expect(
        () => lmsZScore(value: 0, l: 1, m: 10, s: 0.1),
        throwsArgumentError,
      );
      expect(
        () => lmsZScore(value: 10, l: 1, m: 10, s: 0),
        throwsArgumentError,
      );
    });
  });

  group('lmsPercentile', () {
    test('중앙값이면 50%', () {
      expect(lmsPercentile(value: 10, l: 1, m: 10, s: 0.1), closeTo(50, 1e-4));
    });

    test('Z=+1 → ~84.1%, Z=-1 → ~15.9% (L=1, M=10, S=0.1)', () {
      expect(
        lmsPercentile(value: 11, l: 1, m: 10, s: 0.1),
        closeTo(84.13, 0.05),
      );
      expect(
        lmsPercentile(value: 9, l: 1, m: 10, s: 0.1),
        closeTo(15.87, 0.05),
      );
    });

    test('값이 커질수록 백분위가 단조 증가', () {
      final low = lmsPercentile(value: 9, l: 1, m: 10, s: 0.1);
      final mid = lmsPercentile(value: 10, l: 1, m: 10, s: 0.1);
      final high = lmsPercentile(value: 11, l: 1, m: 10, s: 0.1);
      expect(low < mid, isTrue);
      expect(mid < high, isTrue);
    });

    test('백분위는 0~100으로 클램프', () {
      final extreme = lmsPercentile(value: 100, l: 1, m: 10, s: 0.1);
      expect(extreme, lessThanOrEqualTo(100));
      expect(extreme, greaterThanOrEqualTo(0));
    });
  });

  group('percentileFor', () {
    test('GrowthReference로 계산', () {
      const ref = GrowthReference(
        sex: Sex.male,
        type: GrowthType.height,
        ageMonths: 12,
        l: 1,
        m: 10,
        s: 0.1,
      );
      expect(percentileFor(ref, 10), closeTo(50, 1e-4));
      expect(percentileFor(ref, 11), closeTo(84.13, 0.05));
    });
  });
}
