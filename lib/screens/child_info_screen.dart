import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
              Center(
                child: _ChildAvatar(child: c, canEdit: _canEdit),
              ),
              const SizedBox(height: 24),
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

/// 아이 프로필 아바타. 사진이 있으면 원형으로 표시하고, 부모([canEdit])면 카메라
/// 배지로 사진을 교체할 수 있다. 웹·모바일 공용으로 바이트 기반 업로드만 쓴다.
class _ChildAvatar extends StatefulWidget {
  const _ChildAvatar({required this.child, required this.canEdit});

  final Child child;
  final bool canEdit;

  @override
  State<_ChildAvatar> createState() => _ChildAvatarState();
}

class _ChildAvatarState extends State<_ChildAvatar> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('사진을 열 수 없어요.')));
      return;
    }
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = _extensionOf(
        picked.name.isNotEmpty ? picked.name : picked.path,
      );
      final contentType = picked.mimeType ?? _contentTypeForExtension(ext);
      final storageExt = ext.isNotEmpty
          ? ext
          : _extensionForContentType(contentType);
      final url = await scope.storageRepository.uploadChildPhoto(
        groupId: widget.child.id,
        bytes: bytes,
        contentType: contentType,
        extension: storageExt,
      );
      // updateChild는 문서 전체를 set 하므로 copyWith로 다른 필드를 보존한다.
      await scope.groupRepository.updateChild(
        widget.child.id,
        widget.child.copyWith(photoUrl: url),
      );
      messenger.showSnackBar(const SnackBar(content: Text('프로필 사진을 바꿨어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('사진 등록에 실패했어요.')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photoUrl = widget.child.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          // NetworkImage 로드 실패 시 아이콘으로 폴백.
          onBackgroundImageError: hasPhoto ? (_, _) {} : null,
          child: hasPhoto
              ? null
              : Icon(
                  Icons.child_care,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
        ),
        if (_uploading)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (widget.canEdit)
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _changePhoto,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.photo_camera,
                    size: 18,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 파일명/경로에서 소문자 확장자(점 제외)를 뽑는다. 없으면 빈 문자열.
String _extensionOf(String nameOrPath) {
  final dot = nameOrPath.lastIndexOf('.');
  if (dot == -1 || dot == nameOrPath.length - 1) return '';
  final ext = nameOrPath.substring(dot + 1).toLowerCase();
  return ext.length <= 4 ? ext : '';
}

/// 확장자로부터 Storage 규칙(image/.*)을 통과할 contentType을 정한다.
String _contentTypeForExtension(String ext) {
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}

/// contentType으로부터 저장 파일명에 쓸 확장자를 정한다.
String _extensionForContentType(String contentType) {
  switch (contentType) {
    case 'image/png':
      return 'png';
    case 'image/gif':
      return 'gif';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
      return 'heic';
    default:
      return 'jpg';
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
                // 부모가 아니면 마스킹만 보여준다(전체 보기·수정·삭제 없음).
                if (!canEdit) return Text(_masked());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RrnHoldReveal(
                      masked: _masked(),
                      encrypted: child.rrnEncrypted!,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
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

/// 주민번호 "꾹 눌러 보기". 누르고 있는 동안에만 전체 번호를 인라인으로 보여주고
/// 떼면 다시 마스킹으로 돌아간다(부모 전용). 다이얼로그 대신 마찰 없는 열람.
///
/// 전체 값은 [RrnCipher.decryptRrn]로 즉시 복호화한다(부모·본인 기기 한정이라
/// 별도 재인증은 두지 않는다). 복호화 실패 시 조용히 마스킹을 유지한다.
class _RrnHoldReveal extends StatefulWidget {
  const _RrnHoldReveal({required this.masked, required this.encrypted});

  final String masked;
  final String encrypted;

  @override
  State<_RrnHoldReveal> createState() => _RrnHoldRevealState();
}

class _RrnHoldRevealState extends State<_RrnHoldReveal> {
  bool _revealed = false;

  /// 전체 표기: XXXXXX-XXXXXXX. 복호화 실패면 null(마스킹 유지).
  String? _decryptedFormatted() {
    try {
      final digits = RrnCipher.decryptRrn(widget.encrypted);
      return '${digits.substring(0, 6)}-${digits.substring(6)}';
    } catch (_) {
      return null;
    }
  }

  void _reveal() {
    // 누르는 순간 복호화를 시도해 실패하면 마스킹을 유지한다.
    if (_decryptedFormatted() == null) return;
    setState(() => _revealed = true);
  }

  void _hide() {
    if (_revealed) setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    final full = _revealed ? _decryptedFormatted() : null;
    final primary = Theme.of(context).colorScheme.primary;
    // 주민번호 값 옆에 "꾹 눌러 보기"를 둔다(누르는 동안만 전체 표시).
    return Row(
      children: [
        Flexible(child: Text(full ?? widget.masked)),
        const SizedBox(width: 8),
        GestureDetector(
          onTapDown: (_) => _reveal(),
          onTapUp: (_) => _hide(),
          onTapCancel: _hide,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _revealed ? Icons.visibility : Icons.visibility_off,
                size: 18,
                color: primary,
              ),
              const SizedBox(width: 4),
              Text(
                '꾹 눌러 보기',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: primary),
              ),
            ],
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
