# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 프로젝트 지침입니다.

## 프로젝트 개요

학원 출결 관리 앱. 선생님은 여러 학생의 등원/하원을 체크하고, 학부모는 내 아이 한 명의 출결 상태와 달력을 확인한다. 핵심 가치는 "안심" - 학부모는 아이가 학원에 잘 도착했는지 즉시 알 수 있어야 한다.

- 사용자 역할: teacher(선생님), parent(학부모) - 로그인 시 선택하며 화면 트리가 완전히 분리됨
- 선생님: 이메일 로그인 → 오늘 등원 예정 화면(홈), 오늘 출석, 스케줄(주간 편집/월간 보기), 설정(6자리 선생님 코드 확인)
- 학부모: 선생님 코드(6자리 불변) + 자녀 이름으로 회원가입, 이메일 로그인 → 내 아이 출결 화면(홈), 달력, 설정
- 출결 상태: 등원 전(pending) / 등원(present) / 하원(등원·하원 시각 기록) / 결석 예정(expected_absent)

## 기술 스택

- Flutter 3.44.9 / Dart 3.12.2
- Firebase: Auth(이메일 로그인), Cloud Firestore
  - FCM(Cloud Messaging) 푸시는 사용하지 않음 (요청). `firebase_messaging` 미설치, 관련 기능 만들지 않는다.
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
    settings/               # 설정
    shell/                  # 역할별 하단 탭 셸
  shared/widgets/           # 역할 공용 위젯(splash, placeholder 등)
```

각 feature는 `data/`(Repository) · `state/`(Riverpod provider) · 화면/`widgets/`로 구성한다.

## 코딩 규칙

- 색상은 `AppColors`의 토큰만 사용. 위젯 안에서 `Color(0xFF...)`나 `Colors.orange`를 직접 쓰지 않는다. 배경은 화이트/베이지, primary는 오렌지 계열 — 새 색이 필요하면 토큰을 먼저 추가하고 사용한다.
- 간격·모서리·글자 스타일도 토큰만 사용: `AppSpace`(간격), `AppRadius`(모서리), `AppText`(글자 스타일). 모두 `lib/core/theme/`에 정의.
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
flutter build ios --release   # iOS 빌드 (주 테스트 대상)
flutter build apk --release   # 안드로이드 빌드

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
- FCM 푸시 알림은 사용하지 않음 — 관련 기능·패키지를 추가하지 않는다.
