import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/services/map/hospital_finder.dart';

void main() {
  group('HospitalFinder.parseOverpass', () {
    test('이름 있는 node만 파싱한다', () {
      const body = '''
      {"elements":[
        {"type":"node","lat":37.5,"lon":127.0,"tags":{"name":"가나의원","amenity":"clinic"}},
        {"type":"node","lat":37.51,"lon":127.01,"tags":{"amenity":"hospital"}},
        {"type":"node","lat":37.52,"lon":127.02,"tags":{"name":"  ","amenity":"doctors"}},
        {"type":"node","lat":37.53,"lon":127.03,"tags":{"name":"다라병원","amenity":"hospital"}}
      ]}
      ''';
      final places = HospitalFinder.parseOverpass(body);
      expect(places.length, 2);
      expect(places.map((p) => p.name), ['가나의원', '다라병원']);
      expect(places.first.lat, 37.5);
      expect(places.first.lon, 127.0);
    });

    test('좌표 없는 항목은 건너뛴다', () {
      const body = '{"elements":[{"type":"node","tags":{"name":"좌표없음"}}]}';
      expect(HospitalFinder.parseOverpass(body), isEmpty);
    });

    test('빈 결과', () {
      expect(HospitalFinder.parseOverpass('{"elements":[]}'), isEmpty);
    });
  });
}
