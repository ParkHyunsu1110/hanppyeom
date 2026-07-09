import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/services/security/rrn_cipher.dart';

void main() {
  group('RrnCipher', () {
    test('암호화 후 복호화하면 원래 13자리로 돌아온다', () {
      const plain = '9901011234567';
      final encrypted = RrnCipher.encryptRrn(plain);
      expect(RrnCipher.decryptRrn(encrypted), plain);
    });

    test('같은 값도 매번 다른 암호문을 낸다(IV 랜덤)', () {
      const plain = '0001013456789';
      final a = RrnCipher.encryptRrn(plain);
      final b = RrnCipher.encryptRrn(plain);
      expect(a, isNot(b));
      // 그래도 둘 다 같은 평문으로 복호화된다.
      expect(RrnCipher.decryptRrn(a), plain);
      expect(RrnCipher.decryptRrn(b), plain);
    });

    test('암호문에 평문 숫자가 그대로 드러나지 않는다', () {
      const plain = '9901011234567';
      final encrypted = RrnCipher.encryptRrn(plain);
      expect(encrypted.contains(plain), isFalse);
    });
  });
}
