import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/sleep_record.dart';
import 'package:hanppyeom/screens/sleep_screen.dart';

SleepRecord _rec(
  DateTime start,
  DateTime end, [
  SleepKind kind = SleepKind.night,
]) {
  return SleepRecord(
    id: 'r1',
    childId: 'g1',
    groupId: 'g1',
    startAt: start,
    endAt: end,
    kind: kind,
    recordedBy: 'u1',
  );
}

void main() {
  group('splitSleepByDay', () {
    test('같은 날 안에서 끝나면 세그먼트 1개', () {
      final segs = splitSleepByDay(
        _rec(DateTime(2026, 1, 1, 13), DateTime(2026, 1, 1, 14), SleepKind.nap),
      );

      expect(segs.length, 1);
      expect(segs.single.day, DateTime(2026, 1, 1));
      expect(segs.single.start, DateTime(2026, 1, 1, 13));
      expect(segs.single.end, DateTime(2026, 1, 1, 14));
      expect(segs.single.duration, const Duration(hours: 1));
    });

    test('자정을 넘기면 시작일·다음날 세그먼트 2개로 분할', () {
      final rec = _rec(
        DateTime(2026, 1, 1, 20, 10),
        DateTime(2026, 1, 2, 6, 30),
      );
      final segs = splitSleepByDay(rec);

      expect(segs.length, 2);

      // 시작일 세그먼트: 20:10 ~ 24:00(다음날 자정 경계).
      expect(segs[0].day, DateTime(2026, 1, 1));
      expect(segs[0].start, DateTime(2026, 1, 1, 20, 10));
      expect(segs[0].end, DateTime(2026, 1, 2));

      // 다음날 세그먼트: 00:00 ~ 06:30.
      expect(segs[1].day, DateTime(2026, 1, 2));
      expect(segs[1].start, DateTime(2026, 1, 2));
      expect(segs[1].end, DateTime(2026, 1, 2, 6, 30));

      // 원본 레코드를 그대로 들고 있어 수정/삭제가 원본 단위로 동작.
      expect(segs[0].record.id, rec.id);
      expect(segs[1].record.id, rec.id);
    });

    test('세그먼트 길이 합 = 원본 수면 길이', () {
      final rec = _rec(DateTime(2026, 3, 10, 22), DateTime(2026, 3, 11, 7));
      final segs = splitSleepByDay(rec);
      final total = segs.fold<Duration>(
        Duration.zero,
        (sum, s) => sum + s.duration,
      );

      expect(total, rec.duration);
      expect(total, const Duration(hours: 9));
    });
  });
}
