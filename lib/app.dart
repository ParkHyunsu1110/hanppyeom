import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'repositories/group_repository.dart';
import 'repositories/membership_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

/// 한뼘 앱 루트. 서비스 인스턴스를 한 번 만들어 [AppScope]로 내려준다.
class HanppyeomApp extends StatefulWidget {
  const HanppyeomApp({super.key});

  @override
  State<HanppyeomApp> createState() => _HanppyeomAppState();
}

class _HanppyeomAppState extends State<HanppyeomApp> {
  final AuthService _authService = AuthService();
  final GroupRepository _groupRepository = GroupRepository();
  final MembershipRepository _membershipRepository = MembershipRepository();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authService: _authService,
      groupRepository: _groupRepository,
      membershipRepository: _membershipRepository,
      child: MaterialApp(
        title: '한뼘',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8A65)),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
