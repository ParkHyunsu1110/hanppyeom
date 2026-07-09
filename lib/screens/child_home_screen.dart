import 'package:flutter/material.dart';

import '../models/child.dart';
import '../models/membership.dart';
import 'chat_screen.dart';
import 'child_info_screen.dart';
import 'feed_screen.dart';
import 'group_manage_screen.dart';
import 'growth_screen.dart';
import 'membership_display.dart';
import 'sleep_screen.dart';
import 'vaccination_screen.dart';

/// 아이 홈(허브). 한 아이의 기능 화면들로 진입하는 중심.
/// 시작 선택에서 활성 아이를 고르면 이 화면으로 들어온다.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({
    super.key,
    required this.child,
    required this.myMembership,
  });

  final Child child;
  final Membership myMembership;

  @override
  Widget build(BuildContext context) {
    final suffix = roleSuffix(myMembership);
    return Scaffold(
      appBar: AppBar(
        title: Text(child.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              suffix == null
                  ? roleLabel(myMembership)
                  : '${roleLabel(myMembership)} · $suffix',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _FeatureCard(
            icon: Icons.show_chart,
            label: '성장기록',
            onTap: () => _go(
              context,
              GrowthScreen(child: child, myMembership: myMembership),
            ),
          ),
          _FeatureCard(
            icon: Icons.bedtime,
            label: '수면',
            onTap: () => _go(
              context,
              SleepScreen(child: child, myMembership: myMembership),
            ),
          ),
          _FeatureCard(
            icon: Icons.badge,
            label: '아이 정보',
            onTap: () => _go(
              context,
              ChildInfoScreen(child: child, myMembership: myMembership),
            ),
          ),
          _FeatureCard(
            icon: Icons.vaccines,
            label: '예방접종',
            onTap: () => _go(
              context,
              VaccinationScreen(child: child, myMembership: myMembership),
            ),
          ),
          _FeatureCard(
            icon: Icons.photo_library,
            label: '피드',
            onTap: () => _go(
              context,
              FeedScreen(child: child, myMembership: myMembership),
            ),
          ),
          _FeatureCard(
            icon: Icons.chat_bubble,
            label: '채팅',
            onTap: () => _go(
              context,
              ChatScreen(child: child, myMembership: myMembership),
            ),
          ),
          _FeatureCard(
            icon: Icons.group,
            label: '가족·초대',
            onTap: () => _go(
              context,
              GroupManageScreen(child: child, myMembership: myMembership),
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
