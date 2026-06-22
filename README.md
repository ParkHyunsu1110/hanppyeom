# 한뼘 (hanppyeom)

부모가 함께 쓰는 아이 기록·공유 앱. 한 아이의 성장·일상을 가족이 함께 기록하고, 공개 범위를 정해 공유한다. Flutter + Firebase(Auth/Firestore/Storage) 기반.

> 가족 실사용 목적의 프로토타입. 패키지 ID `com.hyunsu.hanppyeom`.

## 핵심 개념

모든 것은 **가족 그룹(FamilyGroup) + 멤버십(Membership)** 위에서 동작한다. 역할(부모/친척)은 사용자가 아니라 멤버십(user↔group)에 붙으며, 데이터 접근·공개범위는 멤버십을 거쳐 검증된다(서버 규칙 강제).

## 기능 (화면 9 + 허브)

- 시작 선택(내 아이 목록·역할 뱃지) · 아이 홈 허브
- 성장기록 + 백분위(WHO 0–5세 + CDC 2–20세 LMS)
- 수면 기록(24시간 띠 시각화)
- 아이 정보 카드(주민번호 마스킹 + 재인증 게이트)
- 예방접종 체크리스트 + 근처 병원 지도(OSM)
- 피드(사진·캡션, 공개범위 가족/부부, 좋아요·댓글)
- 채팅(그룹 단체 대화)
- 가족 그룹·초대(코드 발급·승인)

## 문서

- 문서 라우터 → [`docs/README.md`](docs/README.md)
- 프로젝트 맵 → [`docs/project-map.md`](docs/project-map.md)
- 아키텍처 → [`docs/architecture.md`](docs/architecture.md)
- 빌드/테스트 → [`docs/build-and-test.md`](docs/build-and-test.md)
- 설계 리뷰(PDR) → [`docs/design-reviews/`](docs/design-reviews/)
- 작업 진입 규칙 → [`CLAUDE.md`](CLAUDE.md)

## 빠른 시작

```bash
flutter pub get
flutter run            # 기기/에뮬레이터
flutter analyze lib test
flutter test
```

자세한 내용은 [`docs/build-and-test.md`](docs/build-and-test.md).

## 동작 전 콘솔 선행 작업

- Firebase 콘솔에서 **이메일/비밀번호 로그인 활성화**(로그인 동작 전제)
- **Firebase Storage 'Get Started'** 설정 후 `firebase deploy --only storage`(피드 사진)

## 알려진 한계

- 앱 런타임은 정적 검증(analyze/test)·규칙 에뮬레이터 검증 위주. 실기기 검증 별도 필요.
- 주민등록번호 실제 암호화/복호화는 보안 백엔드(Cloud Functions+KMS) 도입 후(현재 마스킹+재인증 게이트만).
- 5세 초과 성장표는 CDC 사용(이상적으론 질병관리청 2017로 교체 가능).
