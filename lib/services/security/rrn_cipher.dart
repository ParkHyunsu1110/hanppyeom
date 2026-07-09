import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// 주민등록번호(RRN)를 AES로 암·복호화한다.
///
/// 보안 수준 주의: 여기서 쓰는 키는 **앱 바이너리에 내장된 상수**라 난독화 수준이다.
/// 앱 바이너리와 Firestore DB가 동시에 유출되면 복호화가 가능하다. 가족앱이라는
/// 실용 목적에서 내린 사용자 결정이며, 진짜 at-rest 보안이 필요하면 서버 키
/// (Cloud Function/KMS)로 이전해야 한다. Firestore에는 평문/마스킹이 아니라
/// 오직 이 암호문만 저장한다.
class RrnCipher {
  RrnCipher._();

  // 앱 내장 32바이트 AES 키(정확히 32자). 난독화 수준의 보호임에 유의.
  static final Key _key = Key.fromUtf8('hanppyeom_rrn_aes_key_32bytes!!!');

  static final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  /// 숫자 13자리를 암호화한다. 매 호출마다 IV를 랜덤 생성해 암호문 앞에 붙이고
  /// base64(iv + ciphertext)를 반환한다.
  static String encryptRrn(String digits13) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(digits13, iv: iv);
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return Encrypted(combined).base64;
  }

  /// [encryptRrn]로 만든 base64(iv + ciphertext)를 복호화해 평문 13자리를 반환한다.
  static String decryptRrn(String stored) {
    final combined = Encrypted.fromBase64(stored).bytes;
    final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherBytes = Uint8List.fromList(combined.sublist(16));
    return _encrypter.decrypt(Encrypted(cipherBytes), iv: iv);
  }
}
