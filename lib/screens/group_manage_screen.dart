import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/family_group.dart';
import '../models/membership.dart';
import 'membership_display.dart';

/// 가족 그룹·초대 관리 화면. 초대 코드 공유/재발급, 승인 대기 승인/거절, 멤버 목록.
///
/// 권한은 Firestore 규칙이 강제한다. UI는 [myMembership]의 isAdmin으로 관리 액션을 노출한다.
class GroupManageScreen extends StatelessWidget {
  const GroupManageScreen({
    super.key,
    required this.myMembership,
    required this.childName,
  });

  final Membership myMembership;
  final String childName;

  String get _groupId => myMembership.groupId;
  bool get _isAdmin => myMembership.isAdmin;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('$childName · 가족')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    .map((m) => _MemberTile(membership: m))
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
                return Text(
                  code ?? '…',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
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
  const _MemberTile({required this.membership});

  final Membership membership;

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
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              name?.isNotEmpty == true ? name! : roleLabel(membership),
            ),
            subtitle: Text(roleText),
          );
        },
      ),
    );
  }
}
