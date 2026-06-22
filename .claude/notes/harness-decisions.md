# Harness Decisions

이 파일은 **하네스 자체**에 대한 결정만 짧게 기록한다. 제품/기능 설계 결정은 `/pdr`로 `docs/design-reviews/`에 남긴다(혼동하지 않는다).

## 기록 형식

```markdown
## YYYY-MM-DD <한 줄 결정>

- 배경: <왜 결정했는가>
- 적용 범위: <변경한 파일 또는 구성>
- 대안 검토: <고려했다가 선택하지 않은 옵션과 이유>
- 영향: <영향받는 다른 skill/agent/문서>
- 미해결: <남은 질문 또는 없음>
```

## 2026-06-18 hanppyeom에 코드 하네스 적용 (Claude Code 전용)

- 배경: Flutter + Firebase 초기 보일러플레이트에 일관된 작업 흐름(explorer → pdr → coder → reviewer → verify → handoff)과 검증 기준을 갖추기 위해 `template/start.md` 기반 하네스를 적용했다.
- 적용 범위: `CLAUDE.md`, `.mcp.json`, `.claude/agents/{explorer,coder,reviewer}.md`, `.claude/skills/`(기본 7개 + `skill-creator` + `flutter-check`), `.claude/notes/`, `.claude/settings.local.json.example`, `docs/`(README, build-and-test, skill-recommendations).
- 대안 검토: Both(Codex+Claude) 모드는 현재 Codex 사용 계획이 없어 보류 → Claude-only 채택. 따라서 `AGENTS.md`/`.codex/`는 만들지 않았다.
- 영향: `documenter` agent, `docs-sync`/`adapt` skill은 최종 repo에 두지 않는다. 문서 작업은 `docs-organize`/`code-to-docs`가 담당.
- 미해결: 없음.

## 2026-06-18 Context7 MCP 활성화

- 배경: `node v22.18.0`/`npm 10.9.3`/`npx 10.9.3` 확인. Flutter/Firebase 패키지 API 조회에 유용.
- 적용 범위: 루트 `.mcp.json`에 `context7` 서버(npx 실행, 평문 key 없음).
- 대안 검토: 비활성/보류 — 환경이 갖춰져 있어 채택하지 않음.
- 영향: 없음. 상세는 `context7-mcp.md`.
- 미해결: 없음.

## 2026-06-18 custom skill `flutter-check` 채택

- 배경: 코드 변경마다 `dart format`/`flutter analyze`/`flutter test` 점검이 반복된다. `pubspec.yaml`(flutter_lints, flutter_test)과 `analysis_options.yaml`에서 절차·검증 기준이 명확.
- 적용 범위: `.claude/skills/flutter-check/SKILL.md`. 근거 기록은 `docs/skill-recommendations.md`.
- 대안 검토: firestore-rules-check / build_runner-check는 해당 파일(보안 규칙, codegen 의존성)이 없어 보류.
- 영향: 없음. 기본 7개 skill과 책임이 겹치지 않는다(verify는 하네스 검증, flutter-check는 앱 코드 검증).
- 미해결: 없음.
