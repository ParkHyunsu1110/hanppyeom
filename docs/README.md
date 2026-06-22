# Docs

이 폴더는 프로젝트 문서의 진입점이다.

## 문서 라우팅

### 작업 기준
- 프로젝트 설명 → `../README.md`
- 빌드/테스트 → `build-and-test.md`
- 코딩 규칙(린트) → `../analysis_options.yaml`(`package:flutter_lints/flutter.yaml`)
- 작업 진입 규칙 → `../CLAUDE.md`

### 구조 이해
- 프로젝트 맵 → `project-map.md`
- 아키텍처(데이터 흐름·규약·컬렉션) → `architecture.md`
- 모듈별 문서 → `modules/`(현재는 project-map에 통합, 필요 시 분리)
- API 개요 → `api/`(미생성)

### 결정 기록
- 설계 리뷰(PDR) → 신규 기능/화면/API/모듈 또는 큰 동작 변경 시 `design-reviews/`
- 하네스 결정 → `../.claude/notes/harness-decisions.md`

### Skill / MCP
- skill 추천 결과 → `skill-recommendations.md`
- Context7 MCP → `../.claude/notes/context7-mcp.md`

## 운영 원칙

- 하네스 적용 결과에는 이 `docs/README.md`를 항상 둔다.
- 기존 문서가 충분하면 새 문서를 늘리지 말고 이 파일에서 기존 경로를 연결한다.
- 기준이 부족할 때만 `/docs-organize` 또는 `/code-to-docs`로 필요한 문서를 만든다.
- 신규 기능/화면/API/모듈 또는 큰 동작 변경 전에는 `/pdr`로 `design-reviews/<slug>.md`를 짧게 남긴다.
- `/skill-craft`로 custom skill을 만들면 결과는 `.claude/skills/<name>/SKILL.md`에 두고, 채택/보류 근거는 `skill-recommendations.md`에 기록한다.
- 같은 주제는 한 문서에 모으고, stale/보류 문서는 라우터에서 명시한다.
- 프로젝트 규칙·배포 방식·테스트 기준·리뷰 기준이 불명확하면 문서로 단정하지 말고 사용자에게 질문한다.
