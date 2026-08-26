# 지금여기 — 개발 진행 기록

학원 등하원 알림장 앱. 선생님과 학부모를 잇고, "우리 아이가 학원에 잘 도착했는지 실시간으로 안심"하는 것이 핵심 가치.

- 사용자 역할: **선생님(teacher)** / **학부모(parent)** — 역할에 따라 완전히 다른 홈·탭 제공
- 스택: Flutter 3.44 / Dart, Firebase(Auth·Firestore·FCM), Riverpod 3.x, feature-first 폴더 구조

---

## 진행 단계 요약

| Phase | 내용 | 상태 |
|-------|------|------|
| 1 | 프로젝트 세팅 — 구조·테마·역할 분기 라우팅·하단 탭 셸(더미) | ✅ 완료 |
| 2 | Firebase 연동 — Auth, 온보딩(역할선택→코드발급/입력), Firestore 스키마·보안규칙 | ⬜ 예정 |
| 3 | 출석 기능 — 선생님 체크 + attendance 기록, 학부모 라이브 상태 카드 | ⬜ 예정 |
| 4 | 출결 달력 (학부모/선생님 각각) | ⬜ 예정 |
| 5 | 채팅 + 시스템 메시지 칩 | ⬜ 예정 |
| 6 | FCM 푸시 (등원/하원 알림) | ⬜ 예정 |

---

## 초기 결정 사항

- **폴더 구조**: feature-first 채택 (`lib/features/...`, `lib/core/...`). 기존 screens-first 구조에서 이전함.
- **상태관리**: Riverpod을 Phase 1부터 도입. 역할 세션 상태를 `Notifier`로 관리.
- **기존 코드**: 갈아엎지 않고 스펙에 맞게 리팩토링 (필터 칩·헤더·학생 카드 등을 feature 폴더로 이동·정리).

---

## Phase 1 — 완료 (✅)

### 폴더 구조
```
lib/
  main.dart              # ProviderScope로 앱 감쌈
  app.dart               # MaterialApp + 테마 + AppRoot
  core/
    theme/               # app_colors / app_dimens / app_text_styles / app_theme
    router/app_root.dart # 역할 유무로 시작화면 ↔ 탭셸 분기
  models/user_role.dart  # Role { teacher, parent }
  state/session_provider.dart  # 역할 세션 상태(Notifier) — Phase 2에서 Auth로 확장
  features/
    onboarding/          # 역할 선택 시작 화면
    shell/               # 역할별 하단 탭 셸
    home/                # teacher_home / parent_home (placeholder)
    attendance/          # 출석 화면 + widgets(필터/헤더/학생카드) + models
    calendar/ chat/ settings/
  shared/widgets/        # 공용 placeholder 위젯
```

### 디자인 토큰 (`lib/core/theme/`)
색상은 스펙의 정확한 HEX로 정의, 하드코딩 금지.

| 토큰 | 값 | 용도 |
|------|-----|------|
| background | `#FAF7F2` | 웜 화이트/베이지 배경 |
| primary | `#D97757` | 클레이 오렌지 |
| primarySoft | `#F2E3DA` | 연한 오렌지 (등원 표시·뱃지 배경) |
| primaryDeep | `#B54E2C` | 아이콘·강조 텍스트 |
| textMain | `#35302A` | 본문 |
| textSub | `#8C8577` | 보조 텍스트 |
| textFaint | `#9B9384` | 흐린 텍스트 |
| card | `#FFFFFF` | 카드 배경 |
| cardBorder | `#E5DED2` | 카드 헤어라인(0.5px) |
| chipNeutral | `#EFE9DE` | 중립 칩 |

- `ColorScheme.fromSeed(seedColor: primary)` + `scaffoldBackgroundColor` 오버라이드
- 카드 radius 16, 버튼/칩 pill(999)
- 간격 토큰: xs 4 / sm 8 / md 16 / lg 24 / xl 32

### 역할 분기
- 시작 화면에서 **선생님 / 학부모** 선택 → `currentRoleProvider`에 역할 저장
- `AppRoot`가 역할 유무로 분기: 없으면 시작 화면, 있으면 `MainTabScreen(role)`
- 하단 탭 구성이 역할별로 다름
  - 선생님: `홈 / 출석 / 채팅 / 설정`
  - 학부모: `홈 / 달력 / 채팅 / 설정`
- 설정 화면의 "역할 다시 선택"으로 시작 화면 복귀(로그아웃 대용)

### 화면 상태
- **출석 화면(선생님)**: 더미 학생 6명(등원/하원완료/미등원/결석예정), 필터 칩(전체/등원/미등원 + 인원수)으로 리스트 필터링. 학생 카드 상태 버튼(등원=아웃라인, 하원=채워진 primary, 완료/결석예정=상태 pill).
- **홈·달력·채팅·설정**: 후속 Phase용 placeholder (설정만 역할 표시 + 재선택 버튼 동작).

### 검증
- `flutter analyze` 이슈 0
- 스모크 테스트 통과 (`test/widget_test.dart`: 시작 화면 → 선생님 선택 → 탭 셸 진입)

### 실행
```bash
flutter run
```

---

## 다음 작업 (Phase 2 예정 항목)

- Firebase 프로젝트 연결 (Auth·Firestore·FCM), `firebase_options.dart` 생성
- 온보딩 흐름: 역할 선택 → 선생님 회원가입(6자리 코드 자동 발급) / 학부모 회원가입(코드 + 자녀 이름 입력 → 학생 연결)
- `session_provider`를 Firebase Auth 로그인 결과와 연동 (현재는 임시 역할 상태만 보관)
- 라우팅에 온보딩 하위 단계(회원가입/코드 입력) 삽입
- Firestore 초기 스키마 + 보안 규칙 (학부모=자녀 attendance만, 선생님=자기 teacherCode 소속만)
- 설정 화면에 선생님 6자리 코드 표시

### 열어둔 구조 (추후)
- 선생님이 외부 앱으로 초대 링크 전송 — 지금은 구조만 열어둠

---

_마지막 업데이트: Phase 1 완료 시점_
