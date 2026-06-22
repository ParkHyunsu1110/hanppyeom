# Skill Recommendations

`hanppyeom`에 코드 하네스를 적용하며 평가한 custom skill 후보 기록이다.

## 검색 source

- 프로젝트 신호: `pubspec.yaml`(flutter_lints, flutter_test, firebase_*), `analysis_options.yaml`, `firebase.json`, `lib/`, `test/`.
- 외부 skill 마켓 raw copy는 하지 않았다. 후보는 프로젝트에서 확인한 반복 절차를 근거로 도출했다.

## 채택

- `flutter-check` — `dart format` + `flutter analyze` + `flutter test`를 한 번에 점검하는 검증 skill.
  - 근거: 코드 변경마다 반복되는 점검이며, `pubspec.yaml`(flutter_lints, flutter_test)과 `analysis_options.yaml`에서 절차·검증 기준이 명확하다.
  - 최종 경로: `.claude/skills/flutter-check/SKILL.md`
  - 위험도: 낮음(검증 전용, 코드 자동 수정 안 함).

## 기본 권장 예시 복사

- `skill-creator` — Claude 최종 repo 기본 권장 메타 스킬을 `template/examples/`에서 본 템플릿 스타일로 적응 복사.
  - 최종 경로: `.claude/skills/skill-creator/SKILL.md`

## 보류

- `firestore-rules-check` — Firestore 보안 규칙(`firestore.rules`) 파일이 아직 없어 절차/검증 기준이 흐릿. 규칙 파일과 `firebase deploy --only firestore:rules` 운용이 생기면 재검토.
- `build_runner-check` — codegen 의존성(freezed/json_serializable/riverpod_generator 등)이 아직 없어 보류. 코드 생성 도입 시 재검토.
- `release-check` — CI(`.github/`)와 릴리스 절차가 아직 없어 보류. 배포 파이프라인이 굳어지면 재검토.

## 외부 source 사용 정책

- raw copy 금지. 채택 skill(`flutter-check`)은 본 템플릿 스타일(frontmatter + 사용 시점 + 절차 + 검증 + 출력 형식)로 새로 작성했다.
