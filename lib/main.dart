import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/growth/growth_reference_table.dart';
import 'services/vaccine/vaccine_schedule.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 번들 에셋(WHO LMS 기준표 / 표준 접종 일정) 로드. 실패해도 앱은 동작.
  GrowthReferenceTable growthReferenceTable;
  try {
    growthReferenceTable = await GrowthReferenceTable.loadAsset(
      'assets/growth/who_lms.json',
    );
  } catch (_) {
    growthReferenceTable = const GrowthReferenceTable.empty();
  }
  VaccineSchedule vaccineSchedule;
  try {
    vaccineSchedule = await VaccineSchedule.loadAsset(
      'assets/vaccine/schedule_kr.json',
    );
  } catch (_) {
    vaccineSchedule = const VaccineSchedule.empty();
  }
  runApp(
    HanppyeomApp(
      growthReferenceTable: growthReferenceTable,
      vaccineSchedule: vaccineSchedule,
    ),
  );
}
