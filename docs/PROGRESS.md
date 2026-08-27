# 지금여기 — 개발 진행 기록

학원 등하원 알림장 앱. 선생님과 학부모를 잇고, "우리 아이가 학원에 잘 도착했는지 실시간으로 안심"하는 것이 핵심 가치.

- 사용자 역할: **선생님(teacher)** / **학부모(parent)** — 역할에 따라 완전히 다른 홈·탭 제공
- 스택: Flutter 3.44 / Dart, Firebase(Auth·Firestore·FCM), Riverpod 3.x, feature-first 폴더 구조

---

## 진행 단계 요약

| Phase | 내용 | 상태 |
|-------|------|------|
| 1 | 프로젝트 세팅 — 구조·테마·역할 분기 라우팅·하단 탭 셸(더미) | ✅ 완료 |
| 2 | Firebase 연동 — Auth, 온보딩(역할선택→코드발급/입력), Firestore 스키마·보안규칙 | ✅ 완료 (실기기 확인) |
| 3 | 출석 기능 — 선생님 체크 + attendance 기록, 학부모 라이브 상태 카드 | ✅ 완료 (실기기 확인) |
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

---

## Phase 2 — 완료 ✅ (실기기 확인)

- **Firebase 프로젝트**: `jigeum-yeogi-25737` (리전 asia-northeast3 서울)
- 콘솔: https://console.firebase.google.com/project/jigeum-yeogi-25737/overview
- iOS/Android/macOS 앱 등록 완료, Firestore·이메일 인증 활성화, 보안 규칙 배포 완료

### 결정 사항
- **Firebase 프로젝트**: 신규 생성(`flutterfire configure`로 앱 등록).
- **학생 연결**: 학부모 **자가등록** — 코드+자녀 이름 입력 시 `students` 문서를 생성하고 `parentUid` 연결. 선생님 "학생 추가" UI 없이 가입 가능.
- **상태관리**: 역할은 더 이상 수동 토글이 아니라 Firestore `users/{uid}.role`에서 로드 (`appUserProvider`). 기존 `session_provider.dart` 제거.

### 추가된 의존성
- `firebase_core`, `firebase_auth`, `cloud_firestore`

### 구조 (신규/변경)
```
lib/
  core/firebase/firebase_providers.dart   # FirebaseAuth·Firestore 인스턴스 provider
  core/router/app_root.dart               # 인증 상태 기반 라우팅으로 개편
  models/app_user.dart                    # users 문서 매핑
  models/student.dart                     # students 문서 매핑
  features/auth/
    data/auth_repository.dart             # 로그인·회원가입·코드 발급·학생 자가등록
    state/auth_providers.dart             # authState / appUser / repository provider
    onboarding/auth_screen.dart           # 역할별 로그인·회원가입 폼
  shared/widgets/splash_screen.dart       # 로딩 스플래시
firestore.rules                           # 보안 규칙
firebase.json / firestore.indexes.json    # 배포 설정
```

### 인증·온보딩 흐름
- 시작 화면 → 역할 선택 → `AuthScreen(role)` (로그인/회원가입 토글)
- **선생님 회원가입**: 이름/이메일/비번 → Auth 생성 → 고유 6자리 코드 트랜잭션 발급 → `users`(role=teacher, teacherCode) + `teachers/{code}` 문서 생성
- **학부모 회원가입**: + 선생님 코드(검증) + 자녀 이름 → `users`(role=parent) + `students`(parentUid 연결) 배치 생성
- 실패 시 방금 만든 Auth 계정 정리(고아 계정 방지)
- 로그인 상태를 `AppRoot`가 감지 → 역할별 탭 셸 자동 진입
- 설정 화면: 내 정보 + (선생님) 6자리 코드 표시 + 로그아웃

### Firestore 스키마 (실제 생성 필드)
- `users/{uid}`: role, name, email, teacherCode?(선생님), createdAt
- `teachers/{code}`: uid, academyName, classes[], createdAt
- `students/{id}`: name, teacherCode, parentUid, classId, scheduledDays[], createdAt

### 보안 규칙 (`firestore.rules`)
- users: 본인 문서만 read/write, role·teacherCode 변경 불가
- teachers: 로그인 시 read(코드 검증용), 본인 uid로만 create, 수정·삭제 금지
- students: 학부모=본인 자녀만, 선생님=자기 코드 소속만. 학부모 자가등록 create 허용(존재하는 코드로만)
- attendance: 선생님만 쓰기, 학부모=자녀만 읽기
- chats/messages: participants만 접근

### 완료된 설정 (모두 처리됨)
1. ✅ `firebase login` (재인증)
2. ✅ `flutterfire_cli` 설치 + `flutterfire configure`
3. ✅ `lib/firebase_options.dart` 생성 (iOS/Android/macOS)
4. ✅ Authentication → 이메일/비밀번호 활성화
5. ✅ Firestore DB 생성(서울) + 보안 규칙 배포
6. ✅ iOS 최소 버전 15.0 상향 (Firebase SDK 요구)

### ⚠️ 새 환경에서 clone 시 (공개 저장소라 설정 파일 제외됨)
설정 파일은 `.gitignore` 처리되어 있으므로, clone 후 아래를 실행해야 실행 가능:
```
dart pub global activate flutterfire_cli
flutterfire configure --project=jigeum-yeogi-25737
```

---

## Phase 3 — 완료 ✅ (실기기 확인)

### 스키마 개선
- 스펙의 중첩(`attendance/{sid}/records/{date}`) 대신 **최상위 `attendance/{studentId}_{date}`** 채택.
  `teacherCode`·`parentUid`·`date`를 비정규화 → 반 전체/주간 조회를 단순 쿼리로 처리(collectionGroup·복잡한 규칙 회피).

### 구조 (신규)
```
lib/
  core/util/time_format.dart              # 오후 3:02 / 총 2시간30분 포맷
  models/attendance_record.dart           # attendance 문서 매핑 + 상태
  features/attendance/
    data/attendance_repository.dart        # 학생·오늘기록 스트림, 등하원 체크, 주간 조회
    state/attendance_providers.dart        # 선생님/학부모용 Riverpod provider
    attendance_screen.dart                 # 더미 → 실데이터로 교체
  features/home/parent_home_screen.dart    # 라이브 상태 카드 + 주간 통계
```

### 기능
- **선생님 출석 화면**: 내 코드 소속 학생 + 오늘 기록 실시간 표시. 학생 버튼 한 번으로 **등원→하원** 체크(시각 자동 기록). 필터 칩(전체/등원/미등원 인원수).
- **학부모 홈**: 라이브 상태 카드("지금 학원에 있어요" 배지 + 등원 시각/경과, 하원 시 총 체류 시간), 주간 통계 2칸(이번 주 출석 횟수 / 평균 등원 시각).
- **실시간**: 선생님이 등원 체크 → 학부모 화면 즉시 반영.

### Firestore 변경
- attendance 규칙: 최상위 컬렉션 기준으로 재작성(학부모=자녀만 read, 선생님만 write·본인 코드로만)
- 복합 인덱스 2개 배포: `(teacherCode, date)`, `(parentUid, date)`

### attendance 문서 필드
`studentId, teacherCode, parentUid, date(yyyy-MM-dd), checkInAt, checkOutAt, status, updatedAt`

---

## 열어둔 구조 / 다음
- 선생님이 외부 앱으로 초대 링크 전송 — 구조만 열어둠
- 선생님 "학생 추가/관리" 화면 (현재는 학부모 자가등록으로 학생 생성)
- FCM 토큰 저장 필드는 있으나 실제 푸시는 Phase 6
- **Phase 4**: 출결 달력 (학부모/선생님) — 이제 attendance 실데이터를 시각화

---

_마지막 업데이트: Phase 3 완료 시점_
