import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/family_group.dart';
import '../models/membership.dart';
import 'growth_screen.dart';
import 'membership_display.dart';

/// 가족 그룹·초대 관리 화면. 초대 코드 공유/재발급, 승인 대기 승인/거절, 멤버 목록.
///
/// 권한은 Firestore 규칙이 강제한다. UI는 [myMembership]의 isAdmin으로 관리 액션을 노출한다.
class GroupManageScreen extends StatelessWidget {
  const GroupManageScreen({
    super.key,
    required this.myMembership,
    required this.child,
  });

  final Membership myMembership;
  final Child child;

  String get _groupId => myMembership.groupId;
  bool get _isAdmin => myMembership.isAdmin;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${child.name} · 가족')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.show_chart),
            label: const Text('성장기록 보기'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GrowthScreen(child: child, myMembership: myMembership),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InviteCodeCard(groupId: _groupId, isAdmin: _isAdmin),
          const SizedBox(height: 24),
          if (_isAdmin) ...[
            Text('승인 대기', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<Membership>>(
              stream: scope.membershipRepository.watchPendingMembers(_groupId),
              builder: (context, snapshot) {
                final pending = snapshot.data ?? const [];
                if (pending.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('대기 중인 신청이 없어요.'),
                  );
                }
                return Column(
                  children: pending
                      .map((m) => _PendingTile(membership: m))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          Text('가족 구성원', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<Membership>>(
            stream: scope.membershipRepository.watchGroupMembers(_groupId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final members = snapshot.data!.where(
                (m) => m.status == MembershipStatus.active,
              );
              return Column(
                children: members
                    .map(
                      (m) => _MemberTile(
                        membership: m,
                        canManage: _isAdmin && m.userId != myMembership.userId,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.groupId, required this.isAdmin});

  final String groupId;
  final bool isAdmin;

  Future<void> _regenerate(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 코드 재발급'),
        content: const Text('기존 코드는 더 이상 사용할 수 없게 돼요. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('재발급'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await scope.groupRepository.regenerateInviteCode(groupId);
      messenger.showSnackBar(const SnackBar(content: Text('새 초대 코드를 발급했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('재발급에 실패했어요.')));
    }
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(const SnackBar(content: Text('초대 코드를 복사했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('초대 코드', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            StreamBuilder<FamilyGroup?>(
              stream: scope.groupRepository.watchGroup(groupId),
              builder: (context, snapshot) {
                final code = snapshot.data?.inviteCode;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        code ?? '…',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: '초대 코드 복사',
                      icon: const Icon(Icons.copy),
                      onPressed: code == null
                          ? null
                          : () => _copyCode(context, code),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            const Text('이 코드를 가족에게 공유하면 참여 신청할 수 있어요.'),
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('코드 재발급'),
                  onPressed: () => _regenerate(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).membershipRepository;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_add)),
        title: Text(roleLabel(membership)),
        subtitle: const Text('참여를 신청했어요.'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '승인',
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => repo.approve(membership.id),
            ),
            IconButton(
              tooltip: '거절',
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () => repo.remove(membership.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.membership, this.canManage = false});

  final Membership membership;

  /// 관리자가 이 구성원을 관리(역할 지정·내보내기)할 수 있는지(본인 제외).
  /// 규칙도 isGroupAdmin을 강제한다.
  final bool canManage;

  Future<void> _editRole(BuildContext context) async {
    final repo = AppScope.of(context).membershipRepository;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<_RoleAssignment>(
      context: context,
      builder: (_) => _MemberRoleDialog(membership: membership),
    );
    if (result == null) return;
    try {
      await repo.updateRole(
        membershipId: membership.id,
        role: result.role,
        relationType: result.relationType,
        customLabel: result.customLabel,
        isAdmin: result.isAdmin,
      );
      messenger.showSnackBar(const SnackBar(content: Text('역할을 지정했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('역할 지정에 실패했어요.')));
    }
  }

  Future<void> _remove(BuildContext context, String displayName) async {
    final repo = AppScope.of(context).membershipRepository;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구성원 내보내기'),
        content: Text('$displayName 님을 그룹에서 내보낼까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repo.remove(membership.id);
      messenger.showSnackBar(const SnackBar(content: Text('구성원을 내보냈어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('내보내기에 실패했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AppScope.of(context).authService;
    final suffix = roleSuffix(membership);
    final roleText = suffix == null
        ? roleLabel(membership)
        : '${roleLabel(membership)} · $suffix';

    return Card(
      child: FutureBuilder(
        future: authService.fetchAppUser(membership.userId),
        builder: (context, snapshot) {
          final name = snapshot.data?.displayName;
          final display = name?.isNotEmpty == true
              ? name!
              : roleLabel(membership);
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(display),
            subtitle: Text(roleText),
            trailing: canManage
                ? PopupMenuButton<String>(
                    onSelected: (v) => switch (v) {
                      'role' => _editRole(context),
                      'remove' => _remove(context, display),
                      _ => null,
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'role', child: Text('역할 지정')),
                      PopupMenuItem(value: 'remove', child: Text('내보내기')),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// 역할 지정 다이얼로그 결과. 권한은 [role], 호칭은 [relationType]으로 분리한다.
class _RoleAssignment {
  const _RoleAssignment({
    required this.role,
    this.relationType,
    this.customLabel,
    required this.isAdmin,
  });

  final MemberRole role;
  final RelationType? relationType;

  /// [RelationType.etc] 선택 시 자유 입력 호칭.
  final String? customLabel;
  final bool isAdmin;
}

/// 관리자가 구성원의 역할(부모/친척)·호칭·관리자 여부를 지정하는 다이얼로그.
class _MemberRoleDialog extends StatefulWidget {
  const _MemberRoleDialog({required this.membership});

  final Membership membership;

  @override
  State<_MemberRoleDialog> createState() => _MemberRoleDialogState();
}

class _MemberRoleDialogState extends State<_MemberRoleDialog> {
  late MemberRole _role = widget.membership.role;
  late bool _isAdmin = widget.membership.isAdmin;
  late RelationType? _relationType = widget.membership.relationType;
  late final TextEditingController _label = TextEditingController(
    text: widget.membership.relationType == RelationType.etc
        ? (widget.membership.relationLabel ?? '')
        : '',
  );

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _label.text.trim();
    Navigator.pop(
      context,
      _RoleAssignment(
        role: _role,
        relationType: _relationType,
        customLabel: _relationType == RelationType.etc && label.isNotEmpty
            ? label
            : null,
        isAdmin: _isAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('역할 지정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<MemberRole>(
            segments: const [
              ButtonSegment(value: MemberRole.parent, label: Text('부모')),
              ButtonSegment(value: MemberRole.relative, label: Text('친척')),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RelationType>(
            initialValue: _relationType,
            isExpanded: true,
            // 호칭이 14개라 팝업 높이를 제한해 약 5개만 보이고 나머지는 스크롤.
            menuMaxHeight: 280,
            decoration: const InputDecoration(labelText: '호칭 (선택)'),
            items: [
              for (final t in RelationType.values)
                DropdownMenuItem(
                  value: t,
                  child: Text(t == RelationType.etc ? '기타 (직접 입력)' : t.label),
                ),
            ],
            onChanged: (v) => setState(() => _relationType = v),
          ),
          if (_relationType == RelationType.etc) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: '호칭 직접 입력 (예: 큰이모)'),
            ),
          ],
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('관리자 권한'),
            value: _isAdmin,
            onChanged: (v) => setState(() => _isAdmin = v),
          ),
        ],
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
