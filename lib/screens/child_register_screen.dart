import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';

/// 부모가 새 아이를 등록하는 화면(창립). 성공 시 아이+그룹+창립 멤버십이 생긴다.
class ChildRegisterScreen extends StatefulWidget {
  const ChildRegisterScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ChildRegisterScreen> createState() => _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();

  Sex _sex = Sex.male;
  DateTime? _birthDate;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: '생년월일 선택',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일을 선택해 주세요.')));
      return;
    }

    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);

    try {
      await scope.groupRepository.createChildWithGroup(
        founderUid: widget.uid,
        child: Child(
          id: '',
          name: _nameController.text.trim(),
          birthDate: _birthDate!,
          sex: _sex,
        ),
        relationLabel: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
      );
      messenger.showSnackBar(const SnackBar(content: Text('아이를 등록했어요.')));
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('등록에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthText = _birthDate == null
        ? '생년월일 선택'
        : '${_birthDate!.year}.${_birthDate!.month.toString().padLeft(2, '0')}'
              '.${_birthDate!.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('새 아이 등록')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '아이 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(birthText),
                  onPressed: _pickBirthDate,
                ),
                const SizedBox(height: 16),
                SegmentedButton<Sex>(
                  segments: const [
                    ButtonSegment(value: Sex.male, label: Text('남')),
                    ButtonSegment(value: Sex.female, label: Text('여')),
                  ],
                  selected: {_sex},
                  onSelectionChanged: (s) => setState(() => _sex = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _relationController,
                  decoration: const InputDecoration(
                    labelText: '나의 호칭 (선택, 예: 엄마/아빠)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('등록하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
