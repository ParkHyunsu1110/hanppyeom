import 'package:flutter/widgets.dart';

import 'repositories/group_repository.dart';
import 'repositories/growth_repository.dart';
import 'repositories/membership_repository.dart';
import 'repositories/sleep_repository.dart';
import 'services/auth_service.dart';
import 'services/growth/growth_reference_table.dart';

/// 앱 전역 서비스/레포지토리 의존성 주입. 상태관리 패키지 없이
/// Flutter 기본 InheritedWidget으로 화면에 서비스를 내려준다.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authService,
    required this.groupRepository,
    required this.membershipRepository,
    required this.growthRepository,
    required this.growthReferenceTable,
    required this.sleepRepository,
    required super.child,
  });

  final AuthService authService;
  final GroupRepository groupRepository;
  final MembershipRepository membershipRepository;
  final GrowthRepository growthRepository;
  final GrowthReferenceTable growthReferenceTable;
  final SleepRepository sleepRepository;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope를 위젯 트리에서 찾을 수 없습니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
