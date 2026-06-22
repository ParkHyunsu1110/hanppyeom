# Project Map

`lib/` 코드 구조와 각 모듈의 책임. 코드에서 확인 가능한 사실 위주. SSOT는 코드와 `firestore.rules`.

## 루트 구조

- `lib/` — 앱 코드(모델·레포지토리·서비스·화면·DI)
- `test/` — Dart 단위/위젯 테스트 + `test/firestore_rules/`(Node 규칙 검증)
- `integration_test/` — 실기기용 통합 테스트(에뮬레이터 연결)
- `assets/growth/who_lms.json` — 성장 LMS 기준표(번들)
- `assets/vaccine/schedule_kr.json` — 표준 예방접종 일정(번들)
- `firestore.rules` / `firestore.indexes.json` / `storage.rules` — 보안 규칙·인덱스(SSOT)
- `docs/` — 문서, `docs/design-reviews/` — PDR

## 레이어

```
화면(screens) → AppScope(DI) → repositories / services → Firebase(Auth/Firestore/Storage) · 번들 에셋
```

- 상태관리 패키지 없음. `AppScope`(InheritedWidget)로 서비스 주입, 화면은 `StreamBuilder`로 Firestore 구독.

## 모듈

### app shell
- 위치: `lib/main.dart`, `lib/app.dart`, `lib/app_scope.dart`
- 책임: Firebase 초기화 + 번들 에셋 로드 → 서비스 생성 → `AppScope`로 주입 → `MaterialApp`/`AuthGate`
- 공개 인터페이스: `HanppyeomApp`, `AppScope.of(context)`

### models
- 위치: `lib/models/` (배럴 `models.dart`)
- 책임: Firestore 문서 ↔ Dart 객체 직렬화(`fromDoc`/`toMap`), enum의 wire 값 매핑
- 엔티티: `AppUser`, `Child`, `FamilyGroup`, `Membership`, `GrowthRecord`, `GrowthReference`, `SleepRecord`, `Vaccination`(+`VaccineScheduleItem`), `Post`, `Comment`, `ChatMessage`
- 규약: 문서 id는 본문에 저장하지 않음. enum은 알 수 없는 값에서 최소권한 폴백(role→relative, status→pending)

### repositories
- 위치: `lib/repositories/`
- 책임: Firestore CRUD/구독. 권한은 규칙이 강제(레포는 호출만)
- 구성: `group_repository`(아이+그룹+창립멤버십 배치, 초대코드), `membership_repository`(참여/승인), `growth_repository`, `sleep_repository`, `vaccination_repository`, `feed_repository`(게시물/좋아요/댓글), `chat_repository`, `storage_repository`(사진 업로드)
- 예외: `repository_exceptions.dart`(`InviteCodeNotFoundException`, `AlreadyJoinedException`)

### services
- 위치: `lib/services/`
- `auth_service` — 이메일 인증 + `users/{uid}` 동기화
- `auth/reauth_service` — 민감정보 노출용 재인증(local_auth)
- `growth/lms_percentile` — LMS(Box-Cox) → 백분위, `growth/growth_reference_table` — 기준표 로드/조회, `growth/age` — 개월수
- `vaccine/vaccine_schedule` — 접종 일정 로드
- `map/hospital_finder` — 현재 위치(geolocator) + 근처 병원(Overpass)

### screens
- 위치: `lib/screens/`
- 진입: `auth_gate`(로그인 분기) → `start_selection_screen`(아이 선택) → `child_home_screen`(허브)
- 기능 화면: `growth_screen`, `sleep_screen`, `child_info_screen`, `vaccination_screen`(+`vaccination_map_screen`), `feed_screen`, `chat_screen`, `group_manage_screen`
- 인증/등록: `auth/auth_screen`, `child_register_screen`, `join_group_screen`
- 헬퍼: `membership_display.dart`(역할 라벨)

## 주요 의존(외부)

`firebase_core/auth/firestore/storage`, `fl_chart`(그래프), `image_picker`(사진), `local_auth`(재인증), `flutter_map`/`latlong2`/`geolocator`/`http`(지도). dev: `fake_cloud_firestore`, `integration_test`.

## 관련 문서

- 아키텍처·데이터 흐름·규약 → [`architecture.md`](architecture.md)
- 빌드/테스트 → [`build-and-test.md`](build-and-test.md)
- 설계 결정 → [`design-reviews/`](design-reviews/)
