import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/growth/growth_reference_table.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // WHO 성장도표 LMS 기준표(번들 에셋)를 로드한다. 실패해도 앱은 추세선으로 동작.
  GrowthReferenceTable growthReferenceTable;
  try {
    growthReferenceTable = await GrowthReferenceTable.loadAsset(
      'assets/growth/who_lms.json',
    );
  } catch (_) {
    growthReferenceTable = const GrowthReferenceTable.empty();
  }
  runApp(HanppyeomApp(growthReferenceTable: growthReferenceTable));
}
