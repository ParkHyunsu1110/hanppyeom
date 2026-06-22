# Architecture

데이터 흐름, 의존 방향, Firebase 연결, 핵심 규약. 보안 규칙 본문은 복제하지 않고 `firestore.rules`/`storage.rules`를 SSOT로 참조한다.

## 의존 방향

```
screens ──▶ AppScope(DI) ──▶ repositories ──▶ cloud_firestore / firebase_storage
                         └─▶ services ──────▶ firebase_auth / local_auth / geolocator / http
                                          └─▶ 번들 에셋(assets/)
```

- 단방향: 화면은 레포지토리/서비스에만 의존, 레포지토리는 Firebase SDK에만 의존.
- DI: `AppScope`(InheritedWidget)가 서비스 단일 인스턴스를 보유, `AppScope.of(context)`로 접근.
- 상태: 별도 상태관리 라이브러리 없이 `StreamBuilder`(실시간) + `FutureBuilder`(단발).

## 앱 시작 흐름

1. `main()` — `Firebase.initializeApp` → 번들 에셋 로드(WHO LMS, 접종 일정; 실패 시 빈 폴백)
2. `HanppyeomApp` — 서비스 생성 후 `AppScope`로 주입
3. `AuthGate` — `authStateChanges` 스트림으로 `AuthScreen`(미로그인) ↔ `StartSelectionScreen`(로그인) 분기

## 핵심 규약 ⭐

- **그룹 문서 ID == 아이 문서 ID** — 아이 1명당 그룹 1개. `children/{id}` 접근을 `memberships/{id}_{uid}`로 조인 없이 게이트.
- **멤버십 문서 ID = `{groupId}_{userId}`** — 규칙에서 `get`/`exists` 한 번으로 검증.
- **groupId 비정규화** — 기록/게시물 등에 `groupId`를 들고 있어 child→group 조인 회피.
- **멤버십 게이트** — 그룹 데이터는 ACTIVE 멤버만 접근. PENDING은 차단.
- **역할 권한** — 읽기는 ACTIVE 멤버 전체, 쓰기(기록·아이정보)는 PARENT만.
- **게시물 공개범위** — FAMILY는 ACTIVE 멤버 전체, COUPLE은 PARENT만. 좋아요·댓글은 글의 공개범위를 **상속**(규칙이 글을 `get`해서 판정).
- 권한은 UI가 아니라 **Firestore/Storage 규칙에서 강제**.

## Firestore 컬렉션

| 컬렉션 | 문서 ID | 내용 | 쓰기 권한 |
|---|---|---|---|
| `users` | uid | 계정 프로필 | 본인 |
| `children` | =groupId | 아이 정보 | PARENT |
| `groups` | auto | 그룹·초대코드 | 관리자 |
| `memberships` | `{gid}_{uid}` | 역할·상태 | 창립자/관리자 |
| `inviteCodes` | 코드 | 코드→그룹 매핑(비멤버 조회용) | 관리자/창립 |
| `growthRecords` | auto | 성장 측정 | PARENT |
| `sleepRecords` | auto | 수면 | PARENT |
| `vaccinations` | `{gid}_{code}_{dose}` | 접종 완료 | PARENT |
| `posts` | auto | 게시물(공개범위) | 멤버(COUPLE은 PARENT) |
| `likes` | `{postId}_{uid}` | 좋아요 | 본인(글 가독 시) |
| `comments` | auto | 댓글 | 멤버(글 가독 시) |
| `chatMessages` | auto | 단체 대화 | ACTIVE 멤버 |

> 정확한 규칙은 `firestore.rules`, 복합 인덱스는 `firestore.indexes.json`이 SSOT.

## 외부 시스템

- **Firebase Auth** — 이메일/비밀번호(콘솔에서 provider 활성화 필요)
- **Firestore** — 데이터 + 규칙/인덱스(배포됨)
- **Firebase Storage** — 게시물 사진(`posts/{groupId}/`). 콘솔 'Get Started' 후 `storage.rules` 배포 필요
- **OpenStreetMap / Overpass API** — 지도 타일·근처 병원(키 불필요)

## 번들 데이터(읽기 전용)

- `assets/growth/who_lms.json` — 키·체중 0–240개월(WHO 0–60 + CDC 61–240), 머리 0–60. 계산은 `lms_percentile`.
- `assets/vaccine/schedule_kr.json` — 질병관리청 NIP 주요 항목(프로토타입 큐레이션, 검토 필요).

## 검증 전략

- 모델/계산/레포 로직 → `flutter test`(`fake_cloud_firestore`)
- 보안 규칙 → `test/firestore_rules/`(에뮬레이터 + `@firebase/rules-unit-testing`)
- 통합 흐름 → `integration_test/`(실기기). macOS 데스크톱은 firebase_core 이슈로 제외.

## 알려진 한계(설계 메모)

- 주민등록번호: 현재 마스킹 + 재인증 게이트만. 실제 암호화/복호화는 백엔드(KMS) 필요.
- COUPLE 게시물 사진: Storage는 멤버십까지만 게이트(글 문서는 규칙으로 숨김).
- 5세 초과 성장표: CDC 사용. 한국 특화는 KDCA 2017로 교체 가능(구조 유지).
