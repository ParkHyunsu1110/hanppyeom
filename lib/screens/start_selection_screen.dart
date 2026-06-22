import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/child.dart';
import '../models/membership.dart';
import 'child_register_screen.dart';
import 'group_manage_screen.dart';
import 'join_group_screen.dart';
import 'membership_display.dart';

/// 로그인 후 "어느 아이로 들어갈지" 선택하는 화면.
/// 내 멤버십을 나열하고, 새 아이 등록 / 초대 코드 참여로 진입한다.
class StartSelectionScreen extends StatelessWidget {
  const StartSelectionScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('한뼘'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () => scope.authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Membership>>(
        stream: scope.membershipRepository.watchMyMemberships(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CenteredMessage('목록을 불러오지 못했어요.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final memberships = snapshot.data!;
          if (memberships.isEmpty) {
            return const _CenteredMessage('아직 등록된 아이가 없어요.\n아래에서 시작해 보세요.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: memberships.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ChildTile(membership: memberships[i]),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('새 아이 등록'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChildRegisterScreen(uid: uid),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('초대 코드로 참여'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => JoinGroupScreen(uid: uid),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    // 승인 대기 멤버는 그룹/아이 데이터를 읽을 수 없다(규칙). 대기 카드만 표시.
    if (membership.status == MembershipStatus.pending) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.hourglass_empty)),
          title: const Text('승인 대기 중'),
          subtitle: const Text('관리자의 승인을 기다리고 있어요.'),
        ),
      );
    }

    final scope = AppScope.of(context);
    return Card(
      child: StreamBuilder<Child?>(
        stream: scope.groupRepository.watchChild(membership.groupId),
        builder: (context, snapshot) {
          final child = snapshot.data;
          final suffix = roleSuffix(membership);
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.child_care)),
            title: Text(child?.name ?? '불러오는 중…'),
            subtitle: Text(
              suffix == null
                  ? roleLabel(membership)
                  : '${roleLabel(membership)} · $suffix',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: child == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GroupManageScreen(
                        myMembership: membership,
                        childName: child.name,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
