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
              return _DaySection(day: day, records: byDay[day]!);
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<SleepRecord>> _groupByDay(List<SleepRecord> records) {
    final map = <DateTime, List<SleepRecord>>{};
    for (final r in records) {
      final day = DateTime(r.startAt.year, r.startAt.month, r.startAt.day);
      map.putIfAbsent(day, () => []).add(r);
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
  const _DaySection({required this.day, required this.records});

  final DateTime day;
  final List<SleepRecord> records;

  @override
  Widget build(BuildContext context) {
    final total = records.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.duration,
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
                  records: records,
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
            ...records.map(
              (r) => Text(
                '${r.kind == SleepKind.night ? "밤잠" : "낮잠"}  '
                '${_fmtTime(r.startAt)} ~ ${_fmtTime(r.endAt)}  (${_fmtDur(r.duration)})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 하루(0~24시) 위에 수면 블록을 그린다. 자정을 넘는 블록은 해당 날의 끝(24시)으로 클램프.
class _DayBarPainter extends CustomPainter {
  _DayBarPainter({
    required this.records,
    required this.day,
    required this.color,
    required this.trackColor,
  });

  final List<SleepRecord> records;
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
    for (final rec in records) {
      final s = rec.startAt.isBefore(dayStart) ? dayStart : rec.startAt;
      final e = rec.endAt.isAfter(dayEnd) ? dayEnd : rec.endAt;
      if (!e.isAfter(s)) continue;
      final x1 = s.difference(dayStart).inMinutes / (24 * 60) * size.width;
      final x2 = e.difference(dayStart).inMinutes / (24 * 60) * size.width;
      canvas.drawRect(Rect.fromLTRB(x1, 0, x2, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DayBarPainter old) => old.records != records;
}

class _NewSleep {
  const _NewSleep(this.start, this.end, this.kind);
  final DateTime start;
  final DateTime end;
  final SleepKind kind;
}

class _AddSleepSheet extends StatefulWidget {
  const _AddSleepSheet();

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  SleepKind _kind = SleepKind.night;
  late DateTime _start = DateTime.now().subtract(const Duration(hours: 1));
  late DateTime _end = DateTime.now();
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
          Text('수면 추가', style: Theme.of(context).textTheme.titleLarge),
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

String _fmtDateTime(DateTime d) => '${d.month}.${d.day} ${_fmtTime(d)}';

String _fmtDur(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m분';
  return m == 0 ? '$h시간' : '$h시간 $m분';
}
