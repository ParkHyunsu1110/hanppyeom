import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../repositories/repository_exceptions.dart';

/// 초대 코드로 가족 그룹에 참여하는 화면(친척). 성공 시 승인 대기(PENDING) 상태가 된다.
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key, required this.uid});

  final String uid;

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _customRelationController = TextEditingController();
  bool _loading = false;

  // 호칭 프리셋. 마지막 "기타"는 직접 입력을 연다.
  static const _customValue = '__custom__';
  static const _relationOptions = <String>[
    '할머니',
    '할아버지',
    '외할머니',
    '외할아버지',
    '이모',
    '이모부',
    '고모',
    '고모부',
    '삼촌',
    '외삼촌',
    '숙모',
    '외숙모',
    '사촌',
  ];

  /// 선택된 드롭다운 값. null이면 미선택(선택 사항), [_customValue]면 직접 입력.
  String? _selectedRelation;

  @override
  void dispose() {
    _codeController.dispose();
    _customRelationController.dispose();
    super.dispose();
  }

  /// 드롭다운/직접 입력을 종합한 최종 호칭. 비었으면 null.
  String? _resolvedRelationLabel() {
    if (_selectedRelation == null) return null;
    if (_selectedRelation == _customValue) {
      final custom = _customRelationController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selectedRelation;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);

    try {
      await scope.membershipRepository.joinByInviteCode(
        uid: widget.uid,
        code: _codeController.text,
        relationLabel: _resolvedRelationLabel(),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('참여를 신청했어요. 관리자 승인을 기다려 주세요.')),
      );
      navigator.pop();
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('참여에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('초대 코드로 참여')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: '초대 코드',
                    hintText: '예: ABC234',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? '초대 코드를 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '나의 호칭 (선택)'),
                  items: [
                    for (final r in _relationOptions)
                      DropdownMenuItem(value: r, child: Text(r)),
                    const DropdownMenuItem(
                      value: _customValue,
                      child: Text('기타 (직접 입력)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedRelation = v),
                ),
                if (_selectedRelation == _customValue) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customRelationController,
                    decoration: const InputDecoration(
                      labelText: '호칭 직접 입력 (예: 큰이모)',
                    ),
                  ),
                ],
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
                        : const Text('참여 신청'),
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
