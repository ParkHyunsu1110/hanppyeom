import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'repositories/group_repository.dart';
import 'repositories/growth_repository.dart';
import 'repositories/membership_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/feed_repository.dart';
import 'repositories/sleep_repository.dart';
import 'repositories/storage_repository.dart';
import 'repositories/vaccination_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/growth/growth_reference_table.dart';
import 'services/vaccine/vaccine_schedule.dart';

/// 한뼘 앱 루트. 서비스 인스턴스를 한 번 만들어 [AppScope]로 내려준다.
class HanppyeomApp extends StatefulWidget {
  const HanppyeomApp({
    super.key,
    required this.growthReferenceTable,
    required this.vaccineSchedule,
  });

  /// 앱 시작 시 로드한 WHO LMS 기준표(main에서 주입).
  final GrowthReferenceTable growthReferenceTable;

  /// 앱 시작 시 로드한 표준 예방접종 일정(main에서 주입).
  final VaccineSchedule vaccineSchedule;

  @override
  State<HanppyeomApp> createState() => _HanppyeomAppState();
}

class _HanppyeomAppState extends State<HanppyeomApp> {
  final AuthService _authService = AuthService();
  final GroupRepository _groupRepository = GroupRepository();
  final MembershipRepository _membershipRepository = MembershipRepository();
  final GrowthRepository _growthRepository = GrowthRepository();
  final SleepRepository _sleepRepository = SleepRepository();
  final VaccinationRepository _vaccinationRepository = VaccinationRepository();
  final FeedRepository _feedRepository = FeedRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final StorageRepository _storageRepository = StorageRepository();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authService: _authService,
      groupRepository: _groupRepository,
      membershipRepository: _membershipRepository,
      growthRepository: _growthRepository,
      growthReferenceTable: widget.growthReferenceTable,
      sleepRepository: _sleepRepository,
      vaccinationRepository: _vaccinationRepository,
      vaccineSchedule: widget.vaccineSchedule,
      feedRepository: _feedRepository,
      chatRepository: _chatRepository,
      storageRepository: _storageRepository,
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
