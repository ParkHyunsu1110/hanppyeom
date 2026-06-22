---
name: flutter-check
description: Flutter/Dart 변경 후 포맷·정적분석·테스트를 한 번에 점검한다. 코드 수정/리뷰 마무리, 커밋·PR 전, "flutter 검사", "분석 돌려줘", "테스트 통과하는지 확인" 요청에 사용한다.
---

# flutter-check

이 skill은 Flutter/Dart 변경이 포맷·린트·테스트 기준을 통과하는지 한 번에 확인하는 데 쓴다.
검증 전용이며 코드를 자동 수정하지 않는다.

근거: 이 프로젝트의 `pubspec.yaml`에 `flutter_lints`, `flutter_test`가 dev_dependency로 있고, `analysis_options.yaml`이 `package:flutter_lints/flutter.yaml`을 include한다. 명령은 프로젝트에서 확인한 사실 기준이며, 공식 Flutter 명령으로 단정하지 않은 부분은 "확인 필요"로 남긴다.

## 사용 시점

- `lib/` 또는 `test/`의 코드를 추가/수정한 직후.
- `coder` 작업을 마치고 `reviewer`로 넘기기 전, 또는 커밋/PR 전에 회귀를 확인할 때.
- 사용자가 "flutter 검사", "analyze 돌려줘", "테스트 통과하는지 봐줘"처럼 요청할 때.

## 사용하지 않는 경우

- 코드 변경이 전혀 없는 문서/설정만의 변경.
- 빌드 산출물(`flutter build apk|ipa|web`) 생성이 목적일 때 — 그건 별도 빌드 작업이다.
- 의존성 변경 직후 패키지를 아직 안 받았을 때는 절차 1번(`flutter pub get`)을 먼저 수행한다.

## 절차

모든 명령은 cwd = 프로젝트 루트(`/Users/hyunsu/Documents/projects/hanppyeom`, `pubspec.yaml`이 있는 위치), shell = zsh 기준이다.

> 명령 대상을 `lib test`로 스코프한다. 루트(`.`)로 돌리면 `.gitignore` 대상인 `build/`(빌드 산출물·서드파티 패키지 소스)까지 검사해 무관한 이슈 수천 개가 섞인다. 새 최상위 소스 디렉터리가 생기면 대상에 추가한다.

1. (의존성 변경 시에만) 패키지 동기화
   ```bash
   flutter pub get
   ```
2. 포맷 검사 (수정하지 않고 차이만 감지)
   ```bash
   dart format --output=none --set-exit-if-changed lib test
   ```
   - 실패하면 어떤 파일이 포맷에 어긋나는지 보고한다. 사용자가 원하면 `dart format lib test`로 적용을 제안한다(자동 적용하지 않는다).
3. 정적 분석
   ```bash
   flutter analyze lib test
   ```
   - `analysis_options.yaml`의 `flutter_lints` 규칙으로 검사된다. error/warning/info를 분리해 보고한다.
4. 테스트
   ```bash
   flutter test
   ```
   - 실패한 테스트 파일·케이스를 그대로 인용한다.

## 검증 기준

- 포맷: `dart format ... --set-exit-if-changed lib test` 종료 코드 0 → PASS. 0이 아니면 FAIL(변경 필요 파일 보고).
- 분석: `flutter analyze lib test`가 `No issues found!`이면 PASS. 이슈가 있으면 심각도별로 FAIL/경고 분리.
- 테스트: `flutter test`가 `All tests passed!`이면 PASS. 실패 시 FAIL.
- 명령을 실제로 실행하지 못한 경우(예: Flutter SDK 미설치, 디바이스 필요)는 PASS로 쓰지 말고 "미검증"으로 분리한다.

## 출력 형식

```text
## flutter-check 결과
- pub get: 실행 / 생략(의존성 변경 없음)
- dart format: PASS / FAIL / 미검증
- flutter analyze: PASS / FAIL / 미검증
- flutter test: PASS / FAIL / 미검증

## 문제
- <명령>: <에러/실패 인용과 파일:라인>

## 미검증
- <실행하지 못한 항목과 이유>
```
