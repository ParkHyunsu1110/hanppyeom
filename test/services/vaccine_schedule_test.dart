import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/services/vaccine/vaccine_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('번들 예방접종 일정 로드 + 표준 항목 확인', () async {
    final schedule = await VaccineSchedule.loadAsset(
      'assets/vaccine/schedule_kr.json',
    );
    expect(schedule.isEmpty, isFalse);

    // B형간염 1차는 0개월(출생 시).
    final hepb1 = schedule.items.firstWhere(
      (i) => i.code == 'HepB' && i.doseNumber == 1,
    );
    expect(hepb1.ageMonths, 0);

    // DTaP는 기초 3회(2/4/6개월)를 포함.
    final dtap = schedule.items.where((i) => i.code == 'DTaP').toList();
    expect(dtap.length, greaterThanOrEqualTo(3));
    expect(dtap.map((i) => i.ageMonths), containsAll(<int>[2, 4, 6]));
  });
}
