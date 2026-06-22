import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/services/growth/age.dart';

void main() {
  group('ageInMonths', () {
    test('정확히 N개월', () {
      expect(
        ageInMonths(
          birthDate: DateTime(2025, 1, 15),
          at: DateTime(2026, 1, 15),
        ),
        12,
      );
      expect(
        ageInMonths(
          birthDate: DateTime(2025, 1, 15),
          at: DateTime(2025, 7, 15),
        ),
        6,
      );
    });

    test('일자가 생일 전이면 한 달 덜 센다', () {
      expect(
        ageInMonths(
          birthDate: DateTime(2025, 1, 15),
          at: DateTime(2025, 7, 14),
        ),
        5,
      );
    });

    test('출생 이전/같은 날은 0으로 클램프', () {
      expect(
        ageInMonths(
          birthDate: DateTime(2025, 1, 15),
          at: DateTime(2025, 1, 15),
        ),
        0,
      );
      expect(
        ageInMonths(
          birthDate: DateTime(2025, 1, 15),
          at: DateTime(2024, 12, 1),
        ),
        0,
      );
    });
  });
}
