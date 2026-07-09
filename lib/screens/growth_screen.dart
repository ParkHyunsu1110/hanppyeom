import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/growth_record.dart';
import '../models/growth_reference.dart';
import '../models/membership.dart';
import '../services/growth/age.dart';
import '../services/growth/growth_reference_table.dart';
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
                  typeLabel: _typeLabel,
                  canEdit: _canEdit,
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
    required this.typeLabel,
    required this.canEdit,
  });

  final List<GrowthRecord> records;
  final Child child;
  final GrowthType type;
  final String unit;
  final String typeLabel;

  /// 부모(PARENT)만 기록 수정/삭제 가능(규칙과 일치).
  final bool canEdit;

  /// 기존 기록을 프리필한 시트로 수정한다.
  Future<void> _edit(BuildContext context, GrowthRecord record) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_NewRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddRecordSheet(
        typeLabel: typeLabel,
        unit: unit,
        initialValue: record.value,
        initialDate: record.date,
      ),
    );
    if (result == null) return;
    try {
      await scope.growthRepository.updateRecord(
        recordId: record.id,
        value: result.value,
        date: result.date,
      );
      messenger.showSnackBar(const SnackBar(content: Text('기록을 수정했어요.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('수정에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  /// 확인 다이얼로그 후 기록을 삭제한다.
  Future<void> _delete(BuildContext context, GrowthRecord record) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 기록을 삭제해요.'),
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
      await scope.growthRepository.deleteRecord(record.id);
      messenger.showSnackBar(const SnackBar(content: Text('삭제했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (percentileText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            percentileText,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        )
                      else
                        Text(
                          '백분위는 기준표 탑재 후 제공',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 뷰포트에 약 10개 측정점이 보이도록 폭을 잡고, 그보다 많으면
                    // 그래프 안에서 가로 스크롤한다(reverse: 최신이 먼저 보임).
                    final width = math.max(
                      constraints.maxWidth,
                      records.length * (constraints.maxWidth / 10),
                    );
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: SizedBox(
                        width: width,
                        child: _Chart(
                          records: records,
                          child: child,
                          type: type,
                          table: table,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              ...records.reversed.map(
                (r) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.straighten),
                  title: Text('${_trim(r.value)} $unit'),
                  subtitle: Text(_fmtDate(r.date)),
                  trailing: canEdit
                      ? PopupMenuButton<String>(
                          onSelected: (v) => switch (v) {
                            'edit' => _edit(context, r),
                            'delete' => _delete(context, r),
                            _ => null,
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('수정')),
                            PopupMenuItem(value: 'delete', child: Text('삭제')),
                          ],
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 나이(개월)를 X축으로, 국가 기준 백분위 곡선(P3~P97)을 배경에 얹고
/// 그 위에 아이 측정점을 강조해 그린다. 기준표가 없거나 (sex,type) 커브가
/// 없으면 아이 선만 나이 X축으로 표시한다.
class _Chart extends StatelessWidget {
  const _Chart({
    required this.records,
    required this.child,
    required this.type,
    required this.table,
  });

  final List<GrowthRecord> records;
  final Child child;
  final GrowthType type;
  final GrowthReferenceTable table;

  /// 기준 백분위 곡선(라벨, Z 점수). P3/P15/P50/P85/P97.
  static const _percentiles = <(String, double)>[
    ('3', -1.88079),
    ('15', -1.03643),
    ('50', 0.0),
    ('85', 1.03643),
    ('97', 1.88079),
  ];

  /// 기준 커브의 각 나이에서 목표 Z의 값을 계산한 스팟. NaN(정의 안 되는 밑)은 제외.
  static List<FlSpot> _refSpots(List<GrowthReference> curve, double z) {
    final spots = <FlSpot>[];
    for (final ref in curve) {
      final v = lmsValueForZ(l: ref.l, m: ref.m, s: ref.s, z: z);
      if (!v.isNaN) spots.add(FlSpot(ref.ageMonths.toDouble(), v));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final childSpots = [
      for (final r in records)
        FlSpot(
          ageInMonths(birthDate: child.birthDate, at: r.date).toDouble(),
          r.value,
        ),
    ];

    final curve = table.isEmpty
        ? const <GrowthReference>[]
        : table.curve(sex: child.sex, type: type);

    // 기준 곡선 5개를 얇고 옅게 배경으로 깐다(P50만 살짝 강조).
    final refColor = scheme.onSurfaceVariant;
    final refBars = <LineChartBarData>[
      if (curve.isNotEmpty)
        for (final (label, z) in _percentiles)
          LineChartBarData(
            spots: _refSpots(curve, z),
            isCurved: true,
            color: refColor.withValues(alpha: label == '50' ? 0.55 : 0.3),
            barWidth: label == '50' ? 1.5 : 1,
            dotData: const FlDotData(show: false),
          ),
    ];

    final childBar = LineChartBarData(
      spots: childSpots,
      isCurved: false,
      color: scheme.primary,
      barWidth: 3,
      dotData: const FlDotData(show: true),
    );

    // X축은 아이 데이터 주변 나이(개월) 창으로 제한한다. 기준 곡선이 0~240개월
    // 전체로 뻗어 아이 측정점이 눌려 보이는 문제를 막는다(fl_chart가 창 밖을 클립).
    final childXs = [for (final s in childSpots) s.x];
    final childMin = childXs.reduce(math.min);
    final childMax = childXs.reduce(math.max);
    final pad = math.max(3.0, (childMax - childMin) * 0.25);
    final minX = math.max(0.0, childMin - pad);
    final maxX = childMax + pad;
    final span = maxX - minX;
    final interval = span < 1
        ? 1.0
        : span <= 6
        ? 2.0
        : span <= 18
        ? 6.0
        : 12.0;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        // 기준 곡선을 먼저 깔고 아이 선을 위에 얹는다.
        lineBarsData: [...refBars, childBar],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: interval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  '${value.toInt()}개월',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
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
  const _AddRecordSheet({
    required this.typeLabel,
    required this.unit,
    this.initialValue,
    this.initialDate,
  });

  final String typeLabel;
  final String unit;

  /// 값이 있으면 수정 모드로 프리필한다.
  final double? initialValue;
  final DateTime? initialDate;

  bool get isEdit => initialValue != null;

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _valueController = TextEditingController(
    text: widget.initialValue == null ? '' : _trim(widget.initialValue!),
  );
  late DateTime _date = widget.initialDate ?? DateTime.now();

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
              '${widget.typeLabel} 기록 ${widget.isEdit ? "수정" : "추가"}',
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
