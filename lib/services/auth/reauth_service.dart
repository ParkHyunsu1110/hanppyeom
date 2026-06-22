import 'package:local_auth/local_auth.dart';

/// 민감정보(주민등록번호 등) 노출 전 재인증. 생체인증 또는 기기 PIN/패턴.
class ReauthService {
  ReauthService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// 재인증을 요청한다. 성공 시 true. 기기 미지원/취소/실패 시 false.
  Future<bool> authenticate({String reason = '본인 확인을 위해 인증해 주세요.'}) async {
    try {
      final supported =
          await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
      if (!supported) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // 생체 없으면 기기 PIN/패턴 허용
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
