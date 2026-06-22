import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/membership.dart';

/// 아이 정보 카드. 생년월일/성별/혈액형/특이사항 표시·수정(부모).
///
/// 주민등록번호는 민감정보라 이 프로토타입에서는 평문 저장/표시하지 않는다.
/// 마스킹 표시 + "전체 보기(재인증)"는 암호화·재인증 도입 후 활성화 예정(TODO).
class ChildInfoScreen extends StatelessWidget {
  const ChildInfoScreen({
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
      appBar: AppBar(title: Text('${child.name} · 정보')),
      body: StreamBuilder<Child?>(
        stream: scope.groupRepository.watchChild(_groupId),
        initialData: child,
        builder: (context, snapshot) {
          final c = snapshot.data ?? child;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row(context, '이름', c.name),
              _row(context, '생년월일', _fmtDate(c.birthDate)),
              _row(context, '성별', c.sex == Sex.male ? '남' : '여'),
              _row(
                context,
                '혈액형',
                c.bloodType?.isNotEmpty == true ? c.bloodType! : '—',
              ),
              _row(
                context,
                '특이사항',
                c.notes?.isNotEmpty == true ? c.notes! : '—',
              ),
              const Divider(height: 32),
              _RrnRow(),
              if (_canEdit) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('정보 수정'),
                  onPressed: () => _edit(context, c),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, Child current) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final updated = await showModalBottomSheet<Child>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditChildSheet(child: current),
    );
    if (updated == null) return;
    try {
      await scope.groupRepository.updateChild(_groupId, updated);
      messenger.showSnackBar(const SnackBar(content: Text('정보를 저장했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('저장에 실패했어요.')));
    }
  }
}

class _RrnRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text('주민번호', style: Theme.of(context).textTheme.labelLarge),
        ),
        const Expanded(child: Text('******-*******')),
        TextButton(
          onPressed: null, // 재인증·복호화 도입 후 활성화(TODO)
          child: const Text('전체 보기'),
        ),
      ],
    );
  }
}

class _EditChildSheet extends StatefulWidget {
  const _EditChildSheet({required this.child});

  final Child child;

  @override
  State<_EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends State<_EditChildSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.child.name,
  );
  late final TextEditingController _blood = TextEditingController(
    text: widget.child.bloodType ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.child.notes ?? '',
  );
  late Sex _sex = widget.child.sex;
  late DateTime _birthDate = widget.child.birthDate;

  @override
  void dispose() {
    _name.dispose();
    _blood.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.child.copyWith(
        name: _name.text.trim(),
        birthDate: _birthDate,
        sex: _sex,
        bloodType: _blood.text.trim().isEmpty ? null : _blood.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('정보 수정', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름을 입력해 주세요.' : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('생년월일: ${_fmtDate(_birthDate)}'),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 12),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('남')),
                ButtonSegment(value: Sex.female, label: Text('여')),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _blood,
              decoration: const InputDecoration(
                labelText: '혈액형 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '특이사항 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
