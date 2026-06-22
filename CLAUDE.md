# hanppyeom

이 파일은 Claude Code용 짧은 진입점이다. 프로젝트별 세부 지식은 기존 문서나 `docs/`에 두고, 이 파일에는 작업 진입 규칙과 문서 경로만 남긴다.

`hanppyeom`은 Flutter + Firebase(core/auth/firestore/storage) 앱이다. 현재는 초기 단계다.

## 프로젝트 문서

- 기본 프로젝트 설명 → `README.md`
- 문서 라우터 → `docs/README.md`
- 빌드/테스트 참고 → `docs/build-and-test.md`
- 코딩 규칙(린트) → `analysis_options.yaml`(`package:flutter_lints/flutter.yaml`)
- 설계 리뷰(PDR) → 신규 기능/화면/API/모듈 또는 큰 동작 변경 시 `docs/design-reviews/`
- skill 추천 결과 → `docs/skill-recommendations.md`
- 프로젝트 맵/아키텍처 → 미생성(코드가 늘어나면 `/code-to-docs`로 생성)

> 프로젝트 규칙·구조는 `pubspec.yaml`, `firebase.json`, `analysis_options.yaml`, `lib/` 코드를 SSOT로 본다. 이 파일에서는 본문을 복제하지 않고 경로만 인용한다.

## 작업 원칙

- 프로젝트에 이미 있는 규칙, 문체, 금지사항을 우선한다.
- 요청이 모호하면 구현/수정 전에 `/ask`로 필요한 질문만 좁히고 답을 기다린다.
- 비단순 작업은 구현 전에 `explorer`로 구조, 기존 문서, SSOT, 빌드/테스트 명령, 위험 지점을 먼저 요약한다.
- 신규 기능/화면/API/모듈 또는 큰 동작 변경 전에는 `/pdr`로 짧은 Product Design Review를 남긴다.
- 반복 작업 절차가 굳어진 영역이 있으면 `/skill-craft`로 custom skill을 만든다.
- 기존 docs가 어지러우면 `/docs-organize`로 정리한다.
- 코드만 있고 문서가 비어 있으면 `/code-to-docs`로 문서를 만든다.
- 직접 실행/테스트로 검증하지 않은 내용은 검증 완료처럼 말하지 않는다.
- 영향 범위가 큰 변경은 먼저 사이드 이펙트를 설명한다.
- 요청 범위를 벗어난 리팩터링은 하지 않는다.
- 기존 스타일과 패턴을 맞추고 필요한 범위만 수정한다.

## Build / Test

cwd = 프로젝트 루트(`pubspec.yaml` 위치), shell = zsh.

- 의존성 설치 → `flutter pub get`
- 정적 분석 → `flutter analyze lib test`
- 테스트 → `flutter test`
- 포맷 → `dart format lib test` (검사만: `dart format --output=none --set-exit-if-changed lib test`)
- 빌드 → `flutter build apk` | `flutter build ipa` | `flutter build web`
- 위 포맷/분석/테스트를 한 번에 점검 → `/flutter-check`

자세한 내용은 `docs/build-and-test.md`.

## Agent 작업 흐름

```text
/ask (필요 시) → explorer → /pdr (필요 시) → /skill-craft (필요 시)
              → /docs-organize 또는 /code-to-docs (필요 시)
              → coder → reviewer → /verify → /handoff
```

1. 필요한 경우 `/ask`로 scope, 대상, 검증 기준을 먼저 잠근다.
2. 비단순 작업은 `explorer` 에이전트로 구조와 위험 지점을 요약한다.
3. 신규 기능·화면·API·큰 변경 전에 `/pdr`로 Product Design Review를 짧게 남긴다.
4. 반복 작업 절차가 굳어졌으면 `/skill-craft`로 custom skill을 생성한다.
5. 기존 docs 정리가 필요하면 `/docs-organize`, 코드만 있고 문서가 없으면 `/code-to-docs`.
6. `coder` 에이전트로 구현한다.
7. `reviewer` 에이전트로 검토한다.
8. 피드백이 있으면 다시 구현한다.
9. `/verify`로 하네스 상태를, `/flutter-check`로 앱 코드를 완료 전 검증한다.
10. `/handoff`로 결과, 검증, 리스크, **다음 액션 후보**를 짧게 정리한다.

> 기본 agent는 `explorer`, `coder`, `reviewer` 3개다. 별도 `documenter`/`qa` agent를 두지 않는다. 문서 작업은 `/docs-organize`, `/code-to-docs` skill이 맡고, QA 관점은 `reviewer` 체크리스트에서 함께 확인한다.
> 세부 지침은 `.claude/agents/*.md`에 있다.

## Skills

기본 7개 + 프로젝트 적응 2개.

- `/ask` — 모호한 요청을 1~3개 질문으로 좁힌다. 파일 수정 없음.
- `/pdr` — **Product Design Review**: 신규 기능/화면/API/모듈 또는 큰 동작 변경 전에 목표·시나리오·제약·엣지케이스·검증 기준을 `docs/design-reviews/<slug>.md`에 짧게 남긴다. 파일 생성 workflow — 수동 호출 전용.
- `/skill-craft` — 프로젝트 신호와 반복 작업을 근거로 custom skill을 실제 생성한다. 외부 SKILL.md raw copy 금지. 수동 호출 전용.
- `/docs-organize` — 기존 `docs/`와 README를 재배치·구조화하고 `docs/README.md` 라우터를 정비한다. 수동 호출 전용.
- `/code-to-docs` — 코드를 읽고 project-map·architecture·modules 문서를 만든다. 수동 호출 전용.
- `/verify` — 하네스 JSON, frontmatter, 경로, stale 참조를 외부 패키지 없이 검증한다.
- `/handoff` — 결과·검증·리스크 + **다음 액션 후보**를 정리한다.
- `/skill-creator` — 새 SKILL.md를 만드는 메타 스킬. 경험·실수 패턴을 먼저 묻고 작성한다.
- `/flutter-check` — `dart format` + `flutter analyze` + `flutter test`를 한 번에 점검한다(검증 전용).

## Context7 MCP

- Context7은 라이브러리/API 최신 문서 조회용 기본 MCP로 루트 `.mcp.json`에 포함한다.
- Flutter/Firebase 패키지 사용법, 코드 생성, 설정 절차, 버전별 API 확인에는 Context7을 우선 사용한다.
- 프로젝트 내부 규칙, 도메인 정책, 로컬 Firestore 사실은 기존 SSOT와 실제 코드를 우선한다.
- API key는 저장소에 넣지 않는다. 높은 rate limit이 필요하면 개인 환경에서 설정한다. 상세는 `.claude/notes/context7-mcp.md`.

## Hooks / MCP / 호환성

- hooks는 기본 구성에 넣지 않는다.
- Context7 외 MCP는 실제 서버 정의와 자격증명이 확인되기 전까지 넣지 않는다.
- 하네스 자체 변경 결정은 `.claude/notes/harness-decisions.md`에 남긴다. PDR(`/pdr`)과 혼동하지 않는다.

한뼘 (hanppyeom)

부모가 함께 쓰는 아이 기록·공유 앱. 졸업과제였던 안드로이드 산모수첩 앱을 Flutter 기반으로 다시 만들면서 고도화하는 프로젝트.


이 문서는 설계 핸드오프용 컨텍스트다. 너무 길다고 느껴지면 상세 부분은 docs/로 분리하고 이 파일엔 개요·규칙·로드맵만 남겨도 된다.

1. 프로젝트 개요

목적: 가족용 실사용 (포트폴리오/상용 출시가 1차 목표가 아님)
핵심 가치: 한 아이의 성장·일상을 가족이 함께 기록하고, 공개 범위를 정해서 공유
타깃: Android + iOS (추후 web). 부부가 함께 쓰고, 나중에 친척도 합류

2. 기술 스택 / 현재 상태

Flutter (Android + iOS, web 등록은 해둠)
Firebase: Auth, Cloud Firestore, Storage
패키지 ID: com.hyunsu.hanppyeom
상태: 프로젝트 생성됨 → Firebase 연동·main.dart에서 initializeApp 완료 → 기본 앱 실행 확인됨
git: 개인 GitHub github-personal:ParkHyunsu1110/hanppyeom (회사 계정/레포와 분리됨. push 시 SSH alias github-personal 사용)
다음 작업: Phase 1 (인증 + 가족 그룹/멤버십)

3. 핵심 아키텍처 원칙 ⭐

모든 것은 "가족 그룹(FamilyGroup) + 역할(Membership)" 을 중심으로 설계한다.

역할(role)은 사용자나 아이가 아니라 멤버십(user↔group 연결)에 붙는다.

→ 같은 계정이 도윤이네에선 PARENT, 조카 서아네에선 RELATIVE일 수 있다.

부부 동기화, 친척 추가, 게시물 공개범위가 전부 이 구조 위에서 풀린다.
모든 데이터 접근은 멤버십을 거쳐 검증한다 (특히 공개범위·역할).

4. 화면 (9개)

시작 선택 — 로그인 후 "어느 아이로 들어갈지" 선택. 아이마다 내 역할(부모/친척) 뱃지 표시. 하단에 "새 아이 등록(부모로 시작)" / "초대 코드로 참여"
성장기록 + 백분위 — 키/체중 기록, 또래 백분위 곡선 위에 측정점 시각화, 현재 백분위 + 추세
수면 기록 — 24시간 띠로 날짜별 수면 블록을 쌓아 규칙성을 한눈에
아이 정보 카드 — 생년월일/성별/혈액형/특이사항/주민등록번호(마스킹 + 인증 후 전체 노출)
예방접종 + 지도 — 다음 접종 안내, 연령별 일정 체크리스트, 근처 접종 가능 병원 지도
가족 그룹·초대 — 초대 코드 공유로 연결, 멤버별 역할 관리, 초대 수락 대기(PENDING) 표시
피드 — 게시물(사진+캡션), 좋아요·댓글, 공개범위 표시(부부 전용은 자물쇠)
게시물 작성 — 사진+캡션+공개범위 토글(가족 전체 / 우리 부부만)
채팅 — 가족 그룹 단위 단체 대화 (보낸 사람 이름 표시)

5. 데이터 모델

핵심 엔티티와 주요 필드:

User: id, email, displayName, photoUrl
Child: id, name, birthDate, sex(M/F), bloodType, rrnEncrypted(암호화), notes(특이사항)
FamilyGroup: id, childId, inviteCode — 아이 1명당 그룹 1개
Membership ⭐: id, userId, groupId, role(PARENT|RELATIVE), relationLabel(예: "이모"), isAdmin(bool), status(ACTIVE|PENDING)
GrowthRecord: id, childId, groupId, date, type(HEIGHT|WEIGHT|HEAD), value, recordedBy
SleepRecord: id, childId, groupId, startAt, endAt, kind(NIGHT|NAP)
Vaccination: id, childId, vaccineCode, doseNumber, scheduledDate, completedDate, status(DONE|UPCOMING)
Post: id, groupId, authorId, caption, photoUrls[], visibility(FAMILY|COUPLE), likeCount, commentCount, createdAt
Like: id, postId, userId
Comment: id, postId, authorId, text, createdAt
ChatMessage: id, groupId, senderId, text, attachmentUrl, createdAt

참조 데이터 (사용자 데이터 아님, 앱에 번들 / 읽기 전용):

GrowthReference (LMS): sex, type, ageMonths, L, M, S
VaccineSchedule: 연령별 표준 접종 일정

설계 메모:

기록·게시물에 groupId를 비정규화해서 들고 있는다 → 규칙 검증 시 child→group 조인 회피
멤버십 문서 ID = groupId_userId → 조인 없이 get/exists 한 번으로 검증 (Firestore 규칙이 단순·빠름)
백분위는 저장하지 않고 읽을 때 LMS로 계산하는 게 기본 (필요시 스냅샷)

6. 접근 · 보안 규칙 ⭐

멤버십 게이트: 그룹의 모든 데이터는 요청자가 그 groupId에 status=ACTIVE 멤버십이 있어야 접근 가능. PENDING은 접근 불가.
역할 권한
동작PARENT(보호자)RELATIVE(친척)아이 정보·기록(성장·수면·접종) 읽기OO아이 정보·기록 쓰기/수정OX게시물 작성 (FAMILY)OO게시물 작성 (COUPLE)OX좋아요·댓글OO (읽을 수 있는 글만)멤버 관리·코드 재발급isAdmin만X

게시물 공개범위 (서버/Firestore 규칙에서 강제, UI에서만 숨기면 안 됨)

FAMILY: 그룹의 ACTIVE 멤버 전원이 읽기 가능
COUPLE: role=PARENT인 ACTIVE 멤버만 읽기 가능
"부부만"은 사람 2명이 아니라 PARENT 역할로 정의 → 보호자가 추가돼도 규칙을 안 건드려도 됨

좋아요·댓글은 글의 공개범위를 상속 → 친척은 COUPLE 글을 못 읽으니 좋아요·댓글도 자동 차단
주민등록번호: rrnEncrypted로 암호화 저장. 일반 조회 쿼리에 평문/마스킹 텍스트를 절대 싣지 않음. 전체 값은 최근 재인증(생체/PIN) 확인 시에만 별도 함수로 복호화해서 반환 (부모도 재인증 필요).
초대 흐름: 코드 입력 → Membership(status=PENDING) 생성 → 관리자(보호자) 승인 → ACTIVE

Firestore 규칙 예시 (게시물 읽기/작성):

javascriptfunction membership(gid) {
return get(/databases/$(db)/documents/memberships/$(gid + '_' + request.auth.uid)).data;
}
function isActiveMember(gid) {
return exists(/databases/$(db)/documents/memberships/$(gid + '_' + request.auth.uid))
&& membership(gid).status == 'ACTIVE';
}

match /posts/{postId} {
allow read: if isActiveMember(resource.data.groupId)
&& (resource.data.visibility == 'FAMILY'
|| membership(resource.data.groupId).role == 'PARENT');

allow create: if isActiveMember(request.resource.data.groupId)
&& (request.resource.data.visibility == 'FAMILY'
|| membership(request.resource.data.groupId).role == 'PARENT');
}

7. 성장 백분위 (핵심 기능 디테일)

기준: 질병관리청 2017 소아청소년 성장도표 (0–35개월은 WHO 기반, 이후 한국 데이터). 2027 개정 예정이므로 기준표를 교체 가능한 구조로 설계.
데이터 출처: 공공데이터포털 "국민건강보험공단 영유아성장도표 LMS기준" (성별·개월수별 L, M, S). 파일 다운로드 → 로컬 번들(오프라인 우선).
계산 (LMS 방법, Box-Cox): 측정값 X와 해당 개월수·성별의 L·M·S로

Z = ((X/M)^L − 1) / (L·S) (L ≠ 0), Z = ln(X/M) / S (L = 0)
백분위 = Φ(Z) (표준정규 누적확률)

포인트: "또래 평균과 비교"가 아니라 백분위. 단순 그래프가 아니라 현재 백분위 + 이전 대비 추세까지 보여준다.

8. 예방접종 · 지도

표준 접종 일정(질병관리청): 자주 안 바뀌므로 앱에 번들. DB에는 아이별 완료/예정 상태만 저장.
근처 병원: 카카오/네이버 지도 API + 공공데이터포털 병원 정보로 실시간 조회.

9. 개인정보 주의

미성년자 주민등록번호는 민감정보(개인정보보호법). 2024.5 병원 본인확인 강화제도에서 19세 미만은 예외라 "이름+주민번호"로 진료 가능 → 그래서 전체 번호가 필요할 수 있어 암호화 저장 + 재인증 노출 방식을 택함. 평소엔 뒤 6자리 마스킹.

10. 빌드 로드맵

Phase 1: 인증 + 가족 그룹/멤버십 (뼈대, 최우선 — 모든 권한이 여기 얹힘)
Phase 2: 성장기록 + 백분위 (우선 기능, 입력→저장→백분위→그래프까지 수직 슬라이스 한 번 관통)
Phase 3: 수면, 아이 정보(주민번호 마스킹/인증), 예방접종 + 지도
Phase 4: 피드(좋아요·댓글), 채팅
Phase 5: 보안 규칙 정비 + 실제 가족 테스트 — 단, 규칙은 Phase 1~2부터 같이 깔기
v1 최소 범위: 그룹 + 성장기록만으로 먼저 가족이 써보게 하고, 나머지를 붙여간다

11. 명령어 메모

bashflutter run -d chrome          # 빠른 확인 (또는 안드로이드 기기/에뮬)
flutter analyze                # 정적 분석
flutter pub add <pkg>          # 패키지 추가
dart pub global run flutterfire_cli:flutterfire configure  # Firebase 재구성