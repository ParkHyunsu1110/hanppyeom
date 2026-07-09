import 'dart:math' as math;

import '../../models/growth_reference.dart';

/// LMS(Box-Cox) 방법으로 측정값을 표준정규 Z 점수와 백분위로 변환한다.
///
/// 백분위는 저장하지 않고 측정값 + 해당 (성별·유형·개월수)의 L,M,S로 매번 계산한다.

/// Z = ((X/M)^L − 1) / (L·S) (L ≠ 0), Z = ln(X/M) / S (L = 0).
double lmsZScore({
  required double value,
  required double l,
  required double m,
  required double s,
}) {
  if (value <= 0 || m <= 0 || s == 0) {
    throw ArgumentError('value/m는 양수, s는 0이 아니어야 합니다.');
  }
  if (l == 0) {
    return math.log(value / m) / s;
  }
  return (math.pow(value / m, l) - 1) / (l * s);
}

/// 표준정규 누적분포 Φ(z) (0~1). Abramowitz–Stegun 7.1.26 erf 근사 사용.
double standardNormalCdf(double z) {
  return 0.5 * (1 + _erf(z / math.sqrt2));
}

double _erf(double x) {
  // 최대 절대오차 ~1.5e-7.
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  final t = 1 / (1 + p * ax);
  final y =
      1 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

/// 측정값의 백분위(0~100). 범위를 벗어난 극단값은 Φ가 자연스럽게 0/100에 수렴한다.
double lmsPercentile({
  required double value,
  required double l,
  required double m,
  required double s,
}) {
  final z = lmsZScore(value: value, l: l, m: m, s: s);
  return (standardNormalCdf(z) * 100).clamp(0.0, 100.0);
}

/// [GrowthReference]를 이용한 백분위 계산 편의 함수.
double percentileFor(GrowthReference ref, double value) =>
    lmsPercentile(value: value, l: ref.l, m: ref.m, s: ref.s);

/// LMS 역변환: 목표 Z 점수에 해당하는 측정값을 구한다(기준 백분위 곡선용).
///
/// L=0: X = M·exp(S·z), L≠0: X = M·(1 + L·S·z)^(1/L).
double lmsValueForZ({
  required double l,
  required double m,
  required double s,
  required double z,
}) {
  if (l == 0) {
    return m * math.exp(s * z);
  }
  // L≠0에서 밑(1+L·S·z)이 0 이하이면 실수 거듭제곱이 정의되지 않는다. 정상 LMS·
  // 상용 백분위(P3~P97) 범위에선 발생하지 않지만, 비정상 기준행 방어로 NaN을 반환한다.
  final base = 1 + l * s * z;
  if (base <= 0) return double.nan;
  return m * math.pow(base, 1 / l);
}
