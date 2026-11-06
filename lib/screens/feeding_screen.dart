import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/feeding_record.dart';
import '../models/membership.dart';

/// 수유 기록 화면. 날짜별로 수유(모유/분유/이유식)를 최근순으로 보여주고,
/// 부모는 기록을 추가/수정/삭제한다. 권한은 Firestore 규칙이 강제한다.
class FeedingScreen extends StatelessWidget {
  const FeedingScreen({
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
      appBar: AppBar(title: Text('${child.name} · 식사')),
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('식사 추가'),
              onPressed: () => _add(context),
            )
          : null,
      body: StreamBuilder<List<FeedingRecord>>(
        stream: scope.feedingRepository.watchRecords(_groupId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('기록을 불러오지 못했어요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          if (records.isEmpty) {
            return const Center(child: Text('식사 기록이 아직 없어요.'));
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
                records: byDay[day]!,
                canEdit: _canEdit,
              );
            },
          );
        },
      ),
    );
  }

  /// 수유 레코드를 자정 기준 날짜별로 모은다. 각 날짜 안에서는 최근 우선(desc).
  Map<DateTime, List<FeedingRecord>> _groupByDay(List<FeedingRecord> records) {
    final map = <DateTime, List<FeedingRecord>>{};
    for (final r in records) {
      final day = DateTime(r.fedAt.year, r.fedAt.month, r.fedAt.day);
      map.putIfAbsent(day, () => []).add(r);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.fedAt.compareTo(a.fedAt));
    }
    return map;
  }

  Future<void> _add(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewFeeding>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddFeedingSheet(),
    );
    if (result == null) return;
    try {
      await scope.feedingRepository.addRecord(
        groupId: _groupId,
        fedAt: result.fedAt,
        kind: result.kind,
        amountMl: result.amountMl,
        memo: result.memo,
        recordedBy: myMembership.userId,
      );
      messenger.showSnackBar(const SnackBar(content: Text('식사를 기록했어요.')));
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
    required this.records,
    required this.canEdit,
  });

  final DateTime day;

  /// 이 날짜에 속한 수유 기록들(최근 우선).
  final List<FeedingRecord> records;

  /// 부모(PARENT)만 기록 수정/삭제 가능(규칙과 일치).
  final bool canEdit;

  /// 기존 수유 기록을 프리필한 시트로 수정한다.
  Future<void> _edit(BuildContext context, FeedingRecord record) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewFeeding>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddFeedingSheet(
        initialFedAt: record.fedAt,
        initialKind: record.kind,
        initialAmountMl: record.amountMl,
        initialMemo: record.memo,
      ),
    );
    if (result == null) return;
    try {
      await scope.feedingRepository.updateRecord(
        recordId: record.id,
        fedAt: result.fedAt,
        kind: result.kind,
        amountMl: result.amountMl,
        memo: result.memo,
      );
      messenger.showSnackBar(const SnackBar(content: Text('식사 기록을 수정했어요.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('수정에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  /// 확인 다이얼로그 후 수유 기록을 삭제한다.
  Future<void> _delete(BuildContext context, FeedingRecord record) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 식사 기록을 삭제해요.'),
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
      await scope.feedingRepository.deleteRecord(record.id);
      messenger.showSnackBar(const SnackBar(content: Text('삭제했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.year}.${day.month.toString().padLeft(2, '0')}.${day.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ...records.map(
              (r) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_fmtTime(r.fedAt)}  ${r.kind.label}'
                            '${r.amountMl != null ? '  ${r.amountMl}ml' : ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (r.memo != null && r.memo!.isNotEmpty)
                            Text(
                              r.memo!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (canEdit)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      onSelected: (v) => switch (v) {
                        'edit' => _edit(context, r),
                        'delete' => _delete(context, r),
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

class _NewFeeding {
  const _NewFeeding(this.fedAt, this.kind, this.amountMl, this.memo);
  final DateTime fedAt;
  final FeedingKind kind;
  final int? amountMl;
  final String? memo;
}

class _AddFeedingSheet extends StatefulWidget {
  const _AddFeedingSheet({
    this.initialFedAt,
    this.initialKind,
    this.initialAmountMl,
    this.initialMemo,
  });

  /// 값이 있으면 수정 모드로 프리필한다.
  final DateTime? initialFedAt;
  final FeedingKind? initialKind;
  final int? initialAmountMl;
  final String? initialMemo;

  bool get isEdit => initialFedAt != null;

  @override
  State<_AddFeedingSheet> createState() => _AddFeedingSheetState();
}

class _AddFeedingSheetState extends State<_AddFeedingSheet> {
  late FeedingKind _kind = widget.initialKind ?? FeedingKind.breast;
  late DateTime _fedAt = widget.initialFedAt ?? DateTime.now();
  late final TextEditingController _amount = TextEditingController(
    text: widget.initialAmountMl?.toString() ?? '',
  );
  late final TextEditingController _memo = TextEditingController(
    text: widget.initialMemo ?? '',
  );

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fedAt,
      firstDate: DateTime(_fedAt.year - 2),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fedAt),
    );
    if (time == null) return;
    setState(() {
      _fedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final amountText = _amount.text.trim();
    // 빈 값이면 null, 숫자면 파싱(파싱 실패도 null로 안전 처리).
    final amountMl = amountText.isEmpty ? null : int.tryParse(amountText);
    final memoText = _memo.text.trim();
    Navigator.pop(
      context,
      _NewFeeding(_fedAt, _kind, amountMl, memoText.isEmpty ? null : memoText),
    );
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
            widget.isEdit ? '식사 수정' : '식사 추가',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SegmentedButton<FeedingKind>(
            segments: const [
              ButtonSegment(value: FeedingKind.breast, label: Text('모유')),
              ButtonSegment(value: FeedingKind.formula, label: Text('분유')),
              ButtonSegment(value: FeedingKind.solid, label: Text('이유식')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('시각'),
            subtitle: Text(_fmtDateTime(_fedAt)),
            trailing: const Icon(Icons.edit),
            onTap: _pick,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '양 (선택)',
              suffixText: 'ml',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memo,
            decoration: const InputDecoration(labelText: '메모 (선택)'),
          ),
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
