import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// 지도에 표시할 장소(병원/의원).
class Place {
  const Place({required this.name, required this.lat, required this.lon});

  final String name;
  final double lat;
  final double lon;

  LatLng get latLng => LatLng(lat, lon);
}

/// 현재 위치 + 근처 병원/의원 검색. 키 없이 동작(OpenStreetMap Overpass API).
/// 한국 특화 정보(공공데이터/카카오)는 추후 키 확보 시 교체 가능.
class HospitalFinder {
  HospitalFinder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// 위치를 못 얻을 때 기본값(서울시청).
  static const LatLng fallbackCenter = LatLng(37.5665, 126.9780);

  Future<LatLng> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallbackCenter;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return fallbackCenter;
      }
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return fallbackCenter;
    }
  }

  /// 반경(m) 내 병원/의원 검색.
  Future<List<Place>> searchNearby(
    LatLng center, {
    int radiusMeters = 2000,
  }) async {
    final query =
        '[out:json][timeout:25];'
        '(node["amenity"~"hospital|clinic|doctors"]'
        '(around:$radiusMeters,${center.latitude},${center.longitude}););'
        'out center 50;';
    try {
      final resp = await _client
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return [];
      return parseOverpass(resp.body);
    } catch (_) {
      return [];
    }
  }

  /// Overpass JSON 파싱(이름 있는 node만). 테스트를 위해 순수 함수로 분리.
  static List<Place> parseOverpass(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final elements = (json['elements'] as List<dynamic>?) ?? const [];
    final places = <Place>[];
    for (final e in elements) {
      final m = e as Map<String, dynamic>;
      final lat = (m['lat'] as num?)?.toDouble();
      final lon = (m['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      final tags = (m['tags'] as Map<String, dynamic>?) ?? const {};
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      places.add(Place(name: name, lat: lat, lon: lon));
    }
    return places;
  }
}
