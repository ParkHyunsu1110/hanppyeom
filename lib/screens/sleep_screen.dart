import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/membership.dart';
import '../models/sleep_record.dart';

/// 수면 기록 화면. 날짜별 24시간 띠로 수면 블록을 보여주고, 부모는 기록을 추가한다.
class SleepScreen extends StatelessWidget {
  const SleepScreen({
    super.key,
    required this.child,
    required this.myMembership,
  });

  final Child child;
  final Membership myMembership;

  bool get _canEdit => myMembership.role == MemberRole.parent;
  String get _groupId => myMembership.groupId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${child.name} · 수면')),
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('수면 추가'),
              onPressed: () => _add(context),
            )
          : null,
      body: StreamBuilder<List<SleepRecord>>(
        stream: scope.sleepRepository.watchRecords(_groupId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('기록을 불러오지 못했어요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          if (records.isEmpty) {
            return const Center(child: Text('수면 기록이 아직 없어요.'));
          }
          final byDay = _groupByDay(records);
          final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              return _DaySection(
                day: day,
                segments: byDay[day]!,
                canEdit: _canEdit,
              );
            },
          );
        },
      ),
    );
  }

  /// 각 수면 레코드를 자정 경계로 쪼갠 세그먼트를 날짜별로 모은다.
  /// 자정을 넘는 수면은 시작일·다음날 섹션에 각각 나뉘어 표시된다.
  Map<DateTime, List<SleepSegment>> _groupByDay(List<SleepRecord> records) {
    final map = <DateTime, List<SleepSegment>>{};
    for (final r in records) {
      for (final seg in splitSleepByDay(r)) {
        map.putIfAbsent(seg.day, () => []).add(seg);
      }
    }
    // 같은 날 안에서는 시작 시각 순으로 정렬한다.
    for (final segs in map.values) {
      segs.sort((a, b) => a.start.compareTo(b.start));
    }
    return map;
  }

  Future<void> _add(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewSleep>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddSleepSheet(),
    );
    if (result == null) return;
    try {
      await scope.sleepRepository.addRecord(
        groupId: _groupId,
        startAt: result.start,
        endAt: result.end,
        kind: result.kind,
        recordedBy: myMembership.userId,
      );
      messenger.showSnackBar(const SnackBar(content: Text('수면을 기록했어요.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('추가에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.segments,
    required this.canEdit,
  });

  final DateTime day;

  /// 이 날짜에 속한 수면 세그먼트들(자정 분할 결과). 수정/삭제는 원본 레코드 단위.
  final List<SleepSegment> segments;

  /// 부모(PARENT)만 기록 수정/삭제 가능(규칙과 일치).
  final bool canEdit;

  /// 기존 수면 기록을 프리필한 시트로 수정한다.
  Future<void> _edit(BuildContext context, SleepRecord record) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewSleep>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSleepSheet(
        initialStart: record.startAt,
        initialEnd: record.endAt,
        initialKind: record.kind,
      ),
    );
    if (result == null) return;
    try {
      await scope.sleepRepository.updateRecord(
        recordId: record.id,
        startAt: result.start,
        endAt: result.end,
        kind: result.kind,
      );
      messenger.showSnackBar(const SnackBar(content: Text('수면 기록을 수정했어요.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('수정에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  /// 확인 다이얼로그 후 수면 기록을 삭제한다.
  Future<void> _delete(BuildContext context, SleepRecord record) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 수면 기록을 삭제해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await scope.sleepRepository.deleteRecord(record.id);
      messenger.showSnackBar(const SnackBar(content: Text('삭제했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 날짜 총합은 그 날에 속한 세그먼트 길이의 합(자정 넘긴 수면은 날짜별로 나뉜다).
    final total = segments.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.duration,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${day.year}.${day.month.toString().padLeft(2, '0')}.${day.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text('총 ${_fmtDur(total)}'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: CustomPaint(
                size: Size.infinite,
                painter: _DayBarPainter(
                  segments: segments,
                  day: day,
                  color: Theme.of(context).colorScheme.primary,
                  trackColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('0시'), Text('12시'), Text('24시')],
            ),
            const SizedBox(height: 8),
            ...segments.map(
              (seg) => Row(
                children: [
                  Expanded(
                    child: Text(
                      '${seg.record.kind == SleepKind.night ? "밤잠" : "낮잠"}  '
                      '${_fmtTime(seg.start)} ~ ${_fmtSegEnd(seg)}  (${_fmtDur(seg.duration)})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (canEdit)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      onSelected: (v) => switch (v) {
                        // 수정/삭제는 세그먼트가 아니라 원본 레코드 전체에 적용된다.
                        'edit' => _edit(context, seg.record),
                        'delete' => _delete(context, seg.record),
                        _ => null,
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('수정')),
                        PopupMenuItem(value: 'delete', child: Text('삭제')),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 하루(0~24시) 위에 수면 블록을 그린다. 세그먼트는 이미 [day, day+1] 안에 들어와 있고,
/// 방어적으로 남겨둔 클램프도 그 범위를 벗어나지 않으므로 그대로 그린다.
class _DayBarPainter extends CustomPainter {
  _DayBarPainter({
    required this.segments,
    required this.day,
    required this.color,
    required this.trackColor,
  });

  final List<SleepSegment> segments;
  final DateTime day;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(r, Paint()..color = trackColor);

    final dayStart = day;
    final dayEnd = day.add(const Duration(days: 1));
    final paint = Paint()..color = color;
    for (final seg in segments) {
      final s = seg.start.isBefore(dayStart) ? dayStart : seg.start;
      final e = seg.end.isAfter(dayEnd) ? dayEnd : seg.end;
      if (!e.isAfter(s)) continue;
      final x1 = s.difference(dayStart).inMinutes / (24 * 60) * size.width;
      final x2 = e.difference(dayStart).inMinutes / (24 * 60) * size.width;
      canvas.drawRect(Rect.fromLTRB(x1, 0, x2, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DayBarPainter old) => old.segments != segments;
}

/// 자정 경계로 쪼갠 수면 한 조각. 원본 [record]를 그대로 들고 있어
/// (수정/삭제는 원본 레코드 단위로 동작한다) 같은 원본이 두 날짜에 나뉘어도
/// 어느 세그먼트에서든 편집하면 원본 하나를 수정한다.
class SleepSegment {
  const SleepSegment({
    required this.record,
    required this.day,
    required this.start,
    required this.end,
  });

  final SleepRecord record;

  /// 이 세그먼트가 속한 캘린더 날짜(자정).
  final DateTime day;

  /// 이 날짜 안으로 잘린 세그먼트의 시작/끝. 항상 [day, day+1] 안에 든다.
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}

/// 한 수면 레코드를 지나는 각 캘린더 날짜별 세그먼트로 쪼갠다.
/// - 같은 날 안에서 끝나면 1개.
/// - 저녁→새벽처럼 자정을 넘기면 (시작일 …~24:00) + (다음날 00:00~…)로 2개 이상.
/// 보통 1~2개지만 여러 날에 걸쳐도 일반화되어 동작한다.
List<SleepSegment> splitSleepByDay(SleepRecord record) {
  final segments = <SleepSegment>[];
  var day = DateTime(
    record.startAt.year,
    record.startAt.month,
    record.startAt.day,
  );
  while (true) {
    final nextDay = day.add(const Duration(days: 1));
    final segStart = record.startAt.isAfter(day) ? record.startAt : day;
    final segEnd = record.endAt.isBefore(nextDay) ? record.endAt : nextDay;
    if (segEnd.isAfter(segStart)) {
      segments.add(
        SleepSegment(record: record, day: day, start: segStart, end: segEnd),
      );
    }
    if (!record.endAt.isAfter(nextDay)) break;
    day = nextDay;
  }
  // 방어적: 길이 0이거나 역전된 레코드는 시작일 세그먼트 하나로 남긴다.
  if (segments.isEmpty) {
    segments.add(
      SleepSegment(
        record: record,
        day: day,
        start: record.startAt,
        end: record.endAt,
      ),
    );
  }
  return segments;
}

class _NewSleep {
  const _NewSleep(this.start, this.end, this.kind);
  final DateTime start;
  final DateTime end;
  final SleepKind kind;
}

class _AddSleepSheet extends StatefulWidget {
  const _AddSleepSheet({this.initialStart, this.initialEnd, this.initialKind});

  /// 값이 있으면 수정 모드로 프리필한다.
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final SleepKind? initialKind;

  bool get isEdit => initialStart != null;

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  late SleepKind _kind = widget.initialKind ?? SleepKind.night;
  late DateTime _start =
      widget.initialStart ?? DateTime.now().subtract(const Duration(hours: 1));
  late DateTime _end = widget.initialEnd ?? DateTime.now();
  String? _error;

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (!_end.isAfter(_start)) {
      setState(() => _error = '종료가 시작보다 늦어야 해요.');
      return;
    }
    Navigator.pop(context, _NewSleep(_start, _end, _kind));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEdit ? '수면 수정' : '수면 추가',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SegmentedButton<SleepKind>(
            segments: const [
              ButtonSegment(value: SleepKind.night, label: Text('밤잠')),
              ButtonSegment(value: SleepKind.nap, label: Text('낮잠')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('시작'),
            subtitle: Text(_fmtDateTime(_start)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await _pick(_start);
              if (picked != null) setState(() => _start = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('종료'),
            subtitle: Text(_fmtDateTime(_end)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await _pick(_end);
              if (picked != null) setState(() => _end = picked);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('저장')),
        ],
      ),
    );
  }
}

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// 세그먼트 끝이 다음날 자정(경계)이면 "00:00" 대신 "24:00"으로 보여준다.
String _fmtSegEnd(SleepSegment seg) {
  final nextDay = seg.day.add(const Duration(days: 1));
  return seg.end.isBefore(nextDay) ? _fmtTime(seg.end) : '24:00';
}

String _fmtDateTime(DateTime d) => '${d.month}.${d.day} ${_fmtTime(d)}';

String _fmtDur(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m분';
  return m == 0 ? '$h시간' : '$h시간 $m분';
}
