import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/models/models.dart';

void main() {
  group('GrowthRecord', () {
    test('toMap/fromDoc 라운드트립', () async {
      final fs = FakeFirebaseFirestore();
      final record = GrowthRecord(
        id: 'r1',
        childId: 'g1',
        groupId: 'g1',
        date: DateTime(2026, 1, 10),
        type: GrowthType.weight,
        value: 9.4,
        recordedBy: 'u1',
      );
      await fs.doc('growthRecords/r1').set(record.toMap());
      final back = GrowthRecord.fromDoc(await fs.doc('growthRecords/r1').get());

      expect(back.id, 'r1');
      expect(back.groupId, 'g1');
      expect(back.childId, 'g1');
      expect(back.date, DateTime(2026, 1, 10));
      expect(back.type, GrowthType.weight);
      expect(back.value, 9.4);
      expect(back.recordedBy, 'u1');
    });

    test('type은 wire로 저장되고 date는 Timestamp', () {
      final record = GrowthRecord(
        id: 'r1',
        childId: 'g1',
        groupId: 'g1',
        date: DateTime(2026, 1, 10),
        type: GrowthType.head,
        value: 45,
        recordedBy: 'u1',
      );
      expect(record.toMap()['type'], 'HEAD');
      expect(record.toMap()['date'], isA<Timestamp>());
    });

    test('GrowthType.fromWire 폴백', () {
      expect(GrowthType.fromWire('HEIGHT'), GrowthType.height);
      expect(GrowthType.fromWire('WEIGHT'), GrowthType.weight);
      expect(GrowthType.fromWire('X'), isNull);
    });
  });

  group('GrowthReference', () {
    test('toJson/fromJson 라운드트립', () {
      const ref = GrowthReference(
        sex: Sex.female,
        type: GrowthType.height,
        ageMonths: 24,
        l: -0.1,
        m: 86.4,
        s: 0.037,
      );
      final back = GrowthReference.fromJson(ref.toJson());
      expect(back.sex, Sex.female);
      expect(back.type, GrowthType.height);
      expect(back.ageMonths, 24);
      expect(back.l, -0.1);
      expect(back.m, 86.4);
      expect(back.s, 0.037);
    });
  });
}
