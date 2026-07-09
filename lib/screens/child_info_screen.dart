import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/membership.dart';
import '../services/security/rrn_cipher.dart';

/// 아이 정보 카드. 생년월일/성별/혈액형/특이사항 표시·수정(부모).
///
/// 주민등록번호(RRN)는 민감정보라 평문/마스킹을 Firestore에 저장하지 않고
/// [RrnCipher]로 암호화한 암호문만 저장한다(부부 동기화). 평소엔 마스킹 표시,
/// 전체 노출은 부모만 가능(부모 기기·계정 한정이라 별도 재인증은 두지 않는다).
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
              _RrnRow(child: c, canEdit: _canEdit),
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

/// 주민번호 행. 암호문은 Firestore의 [Child.rrnEncrypted]에 저장되고([RrnCipher]로
/// 암·복호화), 마스킹은 복호화 없이 생년월일·성별로 구성한다.
/// 등록/수정/삭제/전체보기 액션은 부모([canEdit])에게만 노출한다.
class _RrnRow extends StatelessWidget {
  const _RrnRow({required this.child, required this.canEdit});

  final Child child;
  final bool canEdit;

  /// 복호화 없이 생년월일·성별로 만든 마스킹. 형식 YYMMDD-G****** .
  /// G=성별자리: 1900년대 남1/여2, 2000년대 남3/여4.
  String _masked() {
    final b = child.birthDate;
    final yy = (b.year % 100).toString().padLeft(2, '0');
    final mm = b.month.toString().padLeft(2, '0');
    final dd = b.day.toString().padLeft(2, '0');
    final is2000s = b.year >= 2000;
    final g = child.sex == Sex.male
        ? (is2000s ? '3' : '1')
        : (is2000s ? '4' : '2');
    return '$yy$mm$dd-$g******';
  }

  /// 전체 표기: XXXXXX-XXXXXXX
  String _formatted(String digits) =>
      '${digits.substring(0, 6)}-${digits.substring(6)}';

  // 전체 보기는 부모(canEdit)에게만 노출되고 본인 로그인 기기에서만 접근하므로,
  // 별도 재인증 없이 바로 복호화해 보여준다(사용자 결정으로 재인증 마찰 제거).
  Future<void> _reveal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final encrypted = child.rrnEncrypted;
    if (encrypted == null) return;
    String digits;
    try {
      digits = RrnCipher.decryptRrn(encrypted);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('복호화에 실패했어요.')));
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주민등록번호'),
        content: Text(
          _formatted(digits),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _editOrRegister(
    BuildContext context, {
    required bool isEdit,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = AppScope.of(context).groupRepository;
    final digits = await showDialog<String>(
      context: context,
      builder: (_) => _RrnEditDialog(isEdit: isEdit),
    );
    if (digits == null || !context.mounted) return;
    try {
      await repo.updateRrn(child.id, RrnCipher.encryptRrn(digits));
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('주민번호를 저장했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('저장에 실패했어요.')));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = AppScope.of(context).groupRepository;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주민번호 삭제'),
        content: const Text('저장된 주민등록번호를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repo.updateRrn(child.id, null);
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('주민번호를 삭제했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRrn = child.rrnEncrypted != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text('주민번호', style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (hasRrn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_masked()),
                    if (canEdit)
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => _reveal(context),
                            child: const Text('전체 보기'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _editOrRegister(context, isEdit: true),
                            child: const Text('수정'),
                          ),
                          TextButton(
                            onPressed: () => _delete(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                  ],
                );
              }
              // 미등록 상태.
              if (!canEdit) {
                return const Text('미등록 (부모만 조회할 수 있어요)');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('미등록'),
                  TextButton.icon(
                    onPressed: () => _editOrRegister(context, isEdit: false),
                    icon: const Icon(Icons.add),
                    label: const Text('주민번호 등록'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 입력 중 숫자만 남겨 13자리로 제한하고, 6자리 뒤에 하이픈을 자동으로 넣는다.
/// (000101-3000000 형식)
class _RrnInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 13) digits = digits.substring(0, 13);
    final text = digits.length > 6
        ? '${digits.substring(0, 6)}-${digits.substring(6)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// 주민번호 입력 다이얼로그. 하이픈 입력을 허용하되 숫자 13자리만 통과시킨다.
class _RrnEditDialog extends StatefulWidget {
  const _RrnEditDialog({required this.isEdit});

  final bool isEdit;

  @override
  State<_RrnEditDialog> createState() => _RrnEditDialogState();
}

class _RrnEditDialogState extends State<_RrnEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    Navigator.pop(context, digits);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? '주민번호 수정' : '주민번호 등록'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [_RrnInputFormatter()],
          decoration: const InputDecoration(
            labelText: '주민등록번호',
            hintText: '000101-3000000',
          ),
          validator: (v) {
            final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
            if (digits.length != 13) return '숫자 13자리를 입력해 주세요.';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
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
              decoration: const InputDecoration(labelText: '이름'),
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
              decoration: const InputDecoration(labelText: '혈액형 (선택)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '특이사항 (선택)'),
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
