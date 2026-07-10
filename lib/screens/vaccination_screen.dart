import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/membership.dart';
import '../models/vaccination.dart';
import 'vaccination_map_screen.dart';

/// 예방접종 체크리스트. 표준 일정 위에 아이별 완료 여부를 표시하고,
/// 부모는 차수별 완료를 체크한다. 지도(근처 병원)는 후속(API 키 필요).
class VaccinationScreen extends StatelessWidget {
  const VaccinationScreen({
    super.key,
    required this.child,
    required this.myMembership,
  });

  final Child child;
  final Membership myMembership;

  bool get _canEdit => myMembership.role == MemberRole.parent;
  String get _groupId => myMembership.groupId;

  DateTime _dueDate(int ageMonths) => DateTime(
    child.birthDate.year,
    child.birthDate.month + ageMonths,
    child.birthDate.day,
  );

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final items = scope.vaccineSchedule.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name} · 예방접종'),
        actions: [
          IconButton(
            tooltip: '근처 병원',
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const VaccinationMapScreen(),
              ),
            ),
          ),
        ],
      ),
      body: scope.vaccineSchedule.isEmpty
          ? const Center(child: Text('접종 일정을 불러오지 못했어요.'))
          : StreamBuilder<List<Vaccination>>(
              stream: scope.vaccinationRepository.watchCompletions(_groupId),
              builder: (context, snapshot) {
                final done = {for (final v in snapshot.data ?? []) v.key: v};
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const _DisclaimerBanner(),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => _DoseTile(
                        item: item,
                        dueDate: _dueDate(item.ageMonths),
                        record: done[item.key],
                        canEdit: _canEdit,
                        onChanged: (v) => _toggle(context, item, v),
                        onEditDate: () =>
                            _editDate(context, item, done[item.key]),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    VaccineScheduleItem item,
    bool done,
  ) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (done) {
        await scope.vaccinationRepository.markDone(
          groupId: _groupId,
          vaccineCode: item.code,
          doseNumber: item.doseNumber,
          completedDate: DateTime.now(),
          recordedBy: myMembership.userId,
        );
      } else {
        await scope.vaccinationRepository.markUndone(
          groupId: _groupId,
          vaccineCode: item.code,
          doseNumber: item.doseNumber,
        );
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('변경에 실패했어요.')));
    }
  }

  /// 이미 완료된 차수의 접종일을 수정한다(동일 문서 ID라 덮어쓰기).
  Future<void> _editDate(
    BuildContext context,
    VaccineScheduleItem item,
    Vaccination? record,
  ) async {
    if (record == null) return;
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: record.completedDate,
      firstDate: child.birthDate,
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    try {
      await scope.vaccinationRepository.markDone(
        groupId: _groupId,
        vaccineCode: item.code,
        doseNumber: item.doseNumber,
        completedDate: picked,
        recordedBy: myMembership.userId,
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('변경에 실패했어요.')));
    }
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '질병관리청 표준예방접종일정(NIP) 주요 항목 기준입니다. '
          '실제 접종은 의료기관·최신 공식 일정을 확인하세요.',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _DoseTile extends StatelessWidget {
  const _DoseTile({
    required this.item,
    required this.dueDate,
    required this.record,
    required this.canEdit,
    required this.onChanged,
    required this.onEditDate,
  });

  final VaccineScheduleItem item;
  final DateTime dueDate;
  final Vaccination? record;
  final bool canEdit;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEditDate;

  @override
  Widget build(BuildContext context) {
    final isDone = record != null;
    final overdue = !isDone && dueDate.isBefore(DateTime.now());
    final ageLabel = item.ageMonths == 0 ? '생후 4주 이내' : '${item.ageMonths}개월';
    final subtitleText = isDone
        ? '접종일 ${_fmtDate(record!.completedDate)}'
        : '권장 $ageLabel${overdue ? "  · 지난 접종" : ""}';
    return Card(
      child: CheckboxListTile(
        value: isDone,
        onChanged: canEdit ? (v) => onChanged(v ?? false) : null,
        title: Text('${item.name} ${item.doseNumber}차'),
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            color: overdue ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDone && canEdit)
              IconButton(
                tooltip: '접종일 수정',
                icon: const Icon(Icons.edit_calendar, size: 20),
                onPressed: onEditDate,
              ),
            Icon(
              isDone ? Icons.check_circle : Icons.vaccines,
              color: isDone ? Colors.green : null,
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
