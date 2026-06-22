import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/vaccination.dart';

/// 표준 예방접종 일정(번들). 출처: 질병관리청 표준예방접종일정(NIP) 주요 항목.
/// ⚠️ 프로토타입용 큐레이션본 — 실사용 전 최신 공식표 검토 필요.
class VaccineSchedule {
  const VaccineSchedule(this.items);

  const VaccineSchedule.empty() : items = const [];

  final List<VaccineScheduleItem> items;

  bool get isEmpty => items.isEmpty;

  factory VaccineSchedule.fromJsonList(List<dynamic> json) {
    return VaccineSchedule(
      json
          .map((e) => VaccineScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static Future<VaccineSchedule> loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return VaccineSchedule.fromJsonList(jsonDecode(raw) as List<dynamic>);
  }
}
