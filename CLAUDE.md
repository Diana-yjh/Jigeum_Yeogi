# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 프로젝트 지침입니다.

## 프로젝트 개요

**오늘출석** — 학원 출결 관리 앱. 선생님은 여러 학생의 등원/하원을 체크하고, 학부모는 아이의 출결 상태와 달력을 확인한다. 핵심 가치는 "안심" - 학부모는 아이가 학원에 잘 도착했는지 즉시 알 수 있어야 한다. (표시 이름만 오늘출석이고, 번들 ID `com.diana.jigeumYeogi`·저장소명·Firebase 프로젝트 ID는 옛 이름 기준 — 바꾸지 않는다.)

- 사용자 역할: teacher(선생님), parent(학부모) - 로그인 시 선택하며 화면 트리가 완전히 분리됨
- 선생님: 이메일 로그인 → 오늘 등원 예정 화면(홈), 오늘 출석, 스케줄(주간 편집/월간 보기), 설정(6자리 선생님 코드 확인)
- 학부모: 선생님 코드(6자리) + 자녀 이름으로 회원가입, 이메일 로그인 → 아이 출결 화면(홈), 달력, 알림함, 설정
- **다중 선생님·다자녀**: 학부모는 선생님 여러 명 연결(`users.teachers {코드:닉네임}` + `teacherColors`), `students` 문서는 아이×선생님 수강 1건 — 같은 이름끼리 한 아이로 묶는다. `teacherCode=''`는 연결 해제 상태(아이·기록 보존, 설정 "이 반에 아이 추가"로 재연결). 홈은 이름 묶음 페이저 + 수강별 리스트, 달력은 아이별 색 + 선생님 색 테두리, 설정은 선생님 블록에서 반 아이 관리
- 출결 상태: 등원 전(pending) / 등원(present) / 하원(등원·하원 시각 기록) / 결석 예정(expected_absent)
- 시각 표기는 앱 전역 오전/오후(`clock()` = "오후 3:02")

## 기술 스택

- Flutter 3.44.9 / Dart 3.12.2
- Firebase: Auth(이메일 로그인), Cloud Firestore, FCM(Cloud Messaging)
  - 등하원 시 학부모 푸시: Cloud Functions(Firestore 트리거) → FCM. `functions/`에 서버 코드.
- 상태관리: Riverpod (flutter_riverpod, `Notifier`/`StreamProvider`/`Provider.family`)
- 달력: table_calendar
- Firebase 프로젝트: `jigeum-yeogi-25737` (리전 asia-northeast3 서울)

## 아키텍처 / 폴더 구조

feature-first 구조. 기능 단위로 폴더를 나누고, 공용 코드는 `core`·`shared`에, 도메인 모델은 `models`에 둔다.

```
lib/
  main.dart                 # Firebase 초기화 + ProviderScope
  app.dart                  # MaterialApp + 테마
  core/
    theme/                  # app_colors / app_dimens / app_text_styles / app_theme
    router/                 # app_root (인증 상태 기반 분기)
    firebase/               # FirebaseAuth·Firestore 인스턴스 provider
    util/                   # time_format 등
  models/                   # app_user, student, attendance_record, user_role
  features/
    onboarding/             # 시작 화면(역할 선택)
    auth/                   # 로그인·회원가입 (data/state/onboarding)
    home/                   # teacher_home / parent_home
    attendance/             # 출석 체크 (data/state/widgets/models)
    calendar/               # 학부모·선생님 달력
    schedule/               # 선생님 스케줄 (요일+시간)
    settings/               # 설정 (이름 수정, 아이 관리, 링크, 회원탈퇴)
    notifications/          # 학부모 알림함 (attendance 파생, 별도 컬렉션 없음)
    shell/                  # 역할별 하단 탭 셸
  shared/widgets/           # 역할 공용 위젯(splash, placeholder 등)
```

각 feature는 `data/`(Repository) · `state/`(Riverpod provider) · 화면/`widgets/`로 구성한다.

## 탭별 요구사항

각 탭의 상세 요구사항은 `docs/specs/<탭이름>.md`에 있다. **해당 탭 작업 전에 반드시 읽는다.**

| 탭 | 파일 |
|----|------|
| 홈 (선생님·학부모) | `docs/specs/home.md` |
| 출석 (선생님) | `docs/specs/attendance.md` |
| 스케줄 (선생님) | `docs/specs/schedule.md` |
| 달력 (학부모) | `docs/specs/calendar.md` |
| 설정 (공통) | `docs/specs/settings.md` |

인덱스: `docs/specs/README.md`

## 코딩 규칙

- 색상은 `AppColors`의 토큰만 사용. 위젯 안에서 `Color(0xFF...)`나 `Colors.orange`를 직접 쓰지 않는다. 배경은 화이트/베이지, primary는 오렌지 계열 — 새 색이 필요하면 토큰을 먼저 추가하고 사용한다.
- 간격·모서리·글자 스타일도 토큰만 사용: `AppSpace`(간격), `AppRadius`(모서리), `AppText`(글자 스타일). 모두 `lib/core/theme/`에 정의.
- 화면에는 `Scaffold` 대신 **`AppScaffold`**(`shared/widgets/app_background.dart`)를 쓴다 — 공용 배경(파스텔 번짐 + 도트)을 그린다. AppBar를 얹으면 `backgroundColor: Colors.transparent`.
- 글씨 확대 대응: 시스템 배율은 0.9~1.3으로 clamp(`app.dart`) 위에 1.12를 곱한다. 고정 크기 위젯은 배율 1.3에서 넘치지 않는지 확인한다(달력 셀은 `CalendarDayNumber` 참고).
- 주석·커밋 메시지·문서는 모두 한국어로 작성한다. 커밋 메시지 예: `feat: 출석 필터 칩 컴포넌트 분리`
- 위젯 파일이 200줄을 넘으면 분리를 고려한다. 재사용되는 위젯은 `shared/widgets/`로 옮긴다.
- Firestore 접근 코드는 `data/` 레이어의 Repository 클래스에만 둔다. 화면에서 `FirebaseFirestore.instance`를 직접 호출하지 않는다.
- 비동기 UI는 `AsyncValue`의 `when`(또는 `.value`)으로 로딩/에러/데이터 상태를 항상 처리한다.
- `print` 대신 `debugPrint` 사용. 배포 코드에는 로그를 남기지 않는다.
- 새 화면을 만들 때는 선생님/학부모 어느 쪽 화면인지 먼저 확인하고, 두 역할이 공유하면 `shared/`에 둔다.

## 자주 쓰는 명령어

```
flutter pub get               # 의존성 설치
flutter run                   # 디버그 실행 (실행 중 r: hot reload, R: hot restart)
flutter analyze               # 정적 분석 — 커밋 전 반드시 경고 0개 확인
dart format lib/              # 포맷팅
flutter test                  # 테스트
flutter build ipa --release        # iOS 배포(.ipa) — 업로드 절차는 docs/RELEASE_IOS.md
flutter build appbundle --release  # Play 업로드용 AAB (android/key.properties 있으면 릴리즈 서명)
flutter build apk --release        # 기기 직접 설치용

firebase deploy --only firestore:rules    # 보안 규칙 배포
firebase deploy --only firestore:indexes  # 인덱스 배포
```

작업 완료 후에는 `flutter analyze`를 실행해 경고가 없는지 확인한 뒤 보고한다.

## 주의사항

- 공개 저장소이므로 `lib/firebase_options.dart`, `**/google-services.json`, `**/GoogleService-Info.plist`는 `.gitignore` 처리되어 있다. 절대 커밋하거나 내용을 출력하지 않는다. clone 후에는 `flutterfire configure --project=jigeum-yeogi-25737`로 재생성해야 실행된다.
- Firestore 보안 규칙(`firestore.rules`)을 수정할 때는 반드시 사용자에게 먼저 설명하고 확인받는다.
- 학생 이름·전화번호 등 개인정보를 로그·테스트 데이터에 실제 값으로 넣지 않는다. 더미 데이터는 "김테스트" 같은 명백한 가짜 이름을 쓴다.
- `pubspec.yaml`에 새 패키지를 추가할 때는 이유를 먼저 설명하고 추가한다.
- 선생님 코드는 불변이다. 코드를 재생성하거나 변경하는 기능은 만들지 않는다.
- 작업 전에 관련 feature 폴더를 먼저 읽고 기존 패턴을 따른다. 큰 구조 변경은 계획을 먼저 제시하고 확인받은 뒤 진행한다.
- 채팅 기능은 요청으로 제거됨 — 다시 추가하지 않는다.
- FCM 푸시: 등하원 시 학부모 알림. 발송은 Cloud Functions(`functions/`)에서만, 클라이언트는 토큰 저장·수신 처리만. 알림함 문구는 `functions/index.js` 발송 문구와 일치시킨다.
- 재업로드 시 `pubspec.yaml` 빌드 번호(`+N`)를 올린다. 배포 체크리스트·계정 작업은 `docs/RELEASE_IOS.md`, Play 설문 답안은 `docs/PLAY_CONSOLE.md`.
- 시뮬레이터/에뮬레이터 실행·배포 절차는 프로젝트 스킬 참고: `.claude/skills/running-simulators/`, `.claude/skills/releasing/`.
- 운영 데이터 스크립트(`functions/scripts/`): 더미 출결 생성/삭제, 심사용 계정 생성. 서비스 계정 키는 저장소 밖 `~/.config/jigeum/serviceAccount.json`.
- 개인정보처리방침·계정 삭제 페이지는 `docs/privacy/`·`docs/account-deletion/`(GitHub Pages로 서빙). 수집 항목·삭제 동작을 바꾸면 함께 갱신한다.
