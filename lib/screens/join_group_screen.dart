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
  final _relationController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _relationController.dispose();
    super.dispose();
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
        relationLabel: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
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
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? '초대 코드를 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _relationController,
                  decoration: const InputDecoration(
                    labelText: '나의 호칭 (선택, 예: 이모/삼촌)',
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
