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
                final done = {for (final v in snapshot.data ?? []) v.key};
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const _DisclaimerBanner(),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => _DoseTile(
                        item: item,
                        dueDate: _dueDate(item.ageMonths),
                        isDone: done.contains(item.key),
                        canEdit: _canEdit,
                        onChanged: (v) => _toggle(context, item, v),
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
    required this.isDone,
    required this.canEdit,
    required this.onChanged,
  });

  final VaccineScheduleItem item;
  final DateTime dueDate;
  final bool isDone;
  final bool canEdit;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final overdue = !isDone && dueDate.isBefore(DateTime.now());
    final ageLabel = item.ageMonths == 0 ? '생후 4주 이내' : '${item.ageMonths}개월';
    return Card(
      child: CheckboxListTile(
        value: isDone,
        onChanged: canEdit ? (v) => onChanged(v ?? false) : null,
        title: Text('${item.name} ${item.doseNumber}차'),
        subtitle: Text(
          '권장 $ageLabel'
          '${overdue ? "  · 지난 접종" : ""}',
          style: TextStyle(
            color: overdue ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        secondary: Icon(
          isDone ? Icons.check_circle : Icons.vaccines,
          color: isDone ? Colors.green : null,
        ),
      ),
    );
  }
}
