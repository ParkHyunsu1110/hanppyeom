# Build & Test

이 문서는 `hanppyeom`(Flutter + Firebase)의 빌드/테스트/실행 명령을 모은다. SSOT는 `pubspec.yaml`, `firebase.json`, `analysis_options.yaml`이며 여기서는 명령만 정리한다. 모든 명령은 cwd = 프로젝트 루트(`pubspec.yaml` 위치), shell = zsh 기준이다.

## 스택 (pubspec.yaml 기준)

- Dart/Flutter SDK 제약: `^3.12.2`
- 런타임 의존성: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cupertino_icons`
- 개발 의존성: `flutter_test`, `flutter_lints`
- 린트: `analysis_options.yaml` → `include: package:flutter_lints/flutter.yaml`
- Firebase 프로젝트: `hanppyeom` (Android / iOS / Web 구성, `lib/firebase_options.dart` 생성됨 — `firebase.json` 참조)

## 의존성

```bash
flutter pub get        # 의존성 설치/동기화
flutter pub upgrade    # 의존성 업그레이드
```

## 정적 분석 / 포맷

대상을 `lib test`로 스코프한다. 루트(`.`)로 돌리면 `.gitignore` 대상인 `build/`(빌드 산출물·서드파티 패키지 소스)까지 검사해 무관한 이슈가 대량으로 섞인다.

```bash
flutter analyze lib test                                      # flutter_lints 규칙으로 분석
dart format lib test                                          # 포맷 적용
dart format --output=none --set-exit-if-changed lib test      # 포맷 검사(수정 없이 차이만 감지, CI용)
```

## 테스트

```bash
flutter test                       # 전체 테스트 (현재 test/widget_test.dart)
flutter test test/widget_test.dart # 단일 파일
```

## 실행

```bash
flutter run            # 연결된 디바이스/에뮬레이터에서 실행
flutter devices        # 사용 가능한 디바이스 확인
```

## 빌드

```bash
flutter build apk      # Android APK
flutter build appbundle# Android App Bundle
flutter build ipa      # iOS (macOS + Xcode 필요)
flutter build web      # Web
```

> macOS/Windows/Linux 플랫폼 디렉터리도 존재하지만 `firebase_options.dart`에서 web/android/ios만 구성되어 있다. 데스크톱 빌드는 별도 Firebase 구성 확인이 필요(확인 필요).

## 한 번에 점검

코드 변경 후 포맷 + 분석 + 테스트를 한 번에 점검하려면 `/flutter-check` skill을 사용한다.

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test
flutter test
```

## Firebase

- 구성 SSOT: `firebase.json`, `lib/firebase_options.dart`(FlutterFire CLI 생성).
- Firebase 구성 변경 시 `flutterfire configure`로 `firebase_options.dart`를 재생성한다(확인 필요 — 팀 설정에 따라 다름).
- 보안 규칙(`firestore.rules`), CI(`.github/`)는 현재 저장소에 없다. 추가되면 이 문서와 라우터를 갱신한다.
