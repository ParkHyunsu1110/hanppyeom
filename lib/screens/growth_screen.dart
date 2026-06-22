import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/growth_record.dart';
import '../models/membership.dart';
import '../services/growth/age.dart';
import '../services/growth/lms_percentile.dart';

/// 성장기록 화면. 유형별 측정 추세를 곡선으로 보고, 기준표가 있으면 백분위도 본다.
/// 입력은 부모(PARENT)만 가능(규칙과 일치).
class GrowthScreen extends StatefulWidget {
  const GrowthScreen({
    super.key,
    required this.child,
    required this.myMembership,
  });

  final Child child;
  final Membership myMembership;

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  GrowthType _type = GrowthType.height;

  bool get _canEdit => widget.myMembership.role == MemberRole.parent;
  String get _groupId => widget.myMembership.groupId;

  String get _unit => _type == GrowthType.weight ? 'kg' : 'cm';
  String get _typeLabel => switch (_type) {
    GrowthType.height => '키',
    GrowthType.weight => '체중',
    GrowthType.head => '머리둘레',
  };

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.child.name} · 성장기록')),
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('기록 추가'),
              onPressed: _openAddSheet,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<GrowthType>(
              segments: const [
                ButtonSegment(value: GrowthType.height, label: Text('키')),
                ButtonSegment(value: GrowthType.weight, label: Text('체중')),
                ButtonSegment(value: GrowthType.head, label: Text('머리둘레')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GrowthRecord>>(
              stream: scope.growthRepository.watchRecords(
                groupId: _groupId,
                type: _type,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('기록을 불러오지 못했어요.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!;
                if (records.isEmpty) {
                  return Center(child: Text('$_typeLabel 기록이 아직 없어요.'));
                }
                return _GrowthBody(
                  records: records,
                  child: widget.child,
                  type: _type,
                  unit: _unit,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddSheet() async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddRecordSheet(typeLabel: _typeLabel, unit: _unit),
    );
    if (result == null) return;

    try {
      await scope.growthRepository.addRecord(
        groupId: _groupId,
        type: _type,
        value: result.value,
        date: result.date,
        recordedBy: widget.myMembership.userId,
      );
      messenger.showSnackBar(const SnackBar(content: Text('기록을 추가했어요.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('추가에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }
}

class _GrowthBody extends StatelessWidget {
  const _GrowthBody({
    required this.records,
    required this.child,
    required this.type,
    required this.unit,
  });

  final List<GrowthRecord> records;
  final Child child;
  final GrowthType type;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final latest = records.last;
    final table = AppScope.of(context).growthReferenceTable;

    String? percentileText;
    if (!table.isEmpty) {
      final ref = table.lookup(
        sex: child.sex,
        type: type,
        ageMonths: ageInMonths(birthDate: child.birthDate, at: latest.date),
      );
      if (ref != null) {
        final p = percentileFor(ref, latest.value);
        percentileText = '또래 중 상위 ${(100 - p).toStringAsFixed(0)}%';
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 측정',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_trim(latest.value)} $unit',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  percentileText ?? '백분위는 기준표 탑재 후 제공',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _Chart(records: records, unit: unit),
        ),
        const SizedBox(height: 16),
        ...records.reversed.map(
          (r) => ListTile(
            dense: true,
            leading: const Icon(Icons.straighten),
            title: Text('${_trim(r.value)} $unit'),
            subtitle: Text(_fmtDate(r.date)),
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.records, required this.unit});

  final List<GrowthRecord> records;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (final r in records)
        FlSpot(r.date.millisecondsSinceEpoch.toDouble(), r.value),
    ];
    final color = Theme.of(context).colorScheme.primary;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// 입력 시트 결과.
class _NewRecord {
  const _NewRecord(this.value, this.date);
  final double value;
  final DateTime date;
}

class _AddRecordSheet extends StatefulWidget {
  const _AddRecordSheet({required this.typeLabel, required this.unit});

  final String typeLabel;
  final String unit;

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_valueController.text.trim());
    Navigator.pop(context, _NewRecord(value, _date));
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.typeLabel} 기록 추가',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: '${widget.typeLabel} (${widget.unit})',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null) return '숫자를 입력해 주세요.';
                if (parsed <= 0) return '0보다 큰 값을 입력해 주세요.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_fmtDate(_date)),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _fmtDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
