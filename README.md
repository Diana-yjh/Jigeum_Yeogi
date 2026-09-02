<div align="center">

<img src="docs/images/hero.png" alt="오늘출석 — 우리아이 출결을 한눈에" width="800">

# 오늘출석

**우리아이 출결을 한눈에** — 선생님과 학부모 모두 하나의 앱으로

학원 등하원 알림장입니다. 선생님이 아이의 등원·하원을 체크하는 순간,
학부모 휴대폰으로 알림이 갑니다.

`출석 체크` · `학생별 스케줄` · `실시간 등원 알림`

</div>

---

## 주요 기능

<table>
  <tr>
    <td width="50%" align="center">
      <img src="docs/images/teacher_attendance.jpg" alt="(선생님) 오늘의 출석 관리" width="380"><br>
      <b>🍎 (선생님) 오늘의 출석 관리</b><br>
      아이들의 출결을 손쉽게 관리할 수 있어요.<br>
      시간대별 그룹핑, 등원·하원 원터치 체크.
    </td>
    <td width="50%" align="center">
      <img src="docs/images/teacher_schedule.jpg" alt="(선생님) 학생별 스케줄 설정" width="380"><br>
      <b>🗓️ (선생님) 학생별 스케줄 설정</b><br>
      수업시간을 간편하게 설정할 수 있어요.<br>
      요일·시간(30분 단위)과 정규/보충 구분.
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="docs/images/parent_home.jpg" alt="(학부모) 아이의 출석 확인" width="380"><br>
      <b>🏠 (학부모) 아이의 출석 확인</b><br>
      아이의 오늘 하루를 한눈에 확인할 수 있어요.<br>
      등하원 타임라인·체류 시간·이번 주 출석.
    </td>
    <td align="center">
      <img src="docs/images/parent_alerts.jpg" alt="(학부모) 출석 알람" width="380"><br>
      <b>🔔 (학부모) 출석 알람</b><br>
      아이의 출결 알람을 시간대별로 모아서 확인할 수 있어요.<br>
      등원·하원 순간 푸시, 지난 알림은 알림함에서.
    </td>
  </tr>
</table>

이 밖에도 —

- **6자리 반 코드**로 연결: 학부모는 코드와 아이 이름만 입력하면 가입 끝
- **월별 출결 달력**: 날짜를 누르면 몇 시부터 몇 시까지 있었는지 타임바로
- **다자녀 지원**: 한 계정으로 여러 아이를 좌우 스와이프로, 달력엔 아이별 색으로
- **안심 설계**: 선생님은 자기 반만, 학부모는 자기 아이만 — 서버 보안 규칙으로 강제
- 광고·추적 없음. 전화번호·위치 정보를 수집하지 않아요

## 기술 스택

| 영역 | 사용 기술 |
|------|-----------|
| 앱 | Flutter · Dart |
| 상태관리 | Riverpod (`Notifier` / `StreamProvider` / `Provider.family`) |
| 백엔드 | Firebase — Auth(이메일), Cloud Firestore(서울 리전), FCM |
| 푸시 | Cloud Functions(Firestore 트리거) → FCM (`functions/`) |
| 구조 | feature-first (`lib/features/…` + `core` / `models` / `shared`) |

```
lib/
  core/        # 테마 토큰(색·간격·글자), 라우팅, Firebase provider, 유틸
  models/      # app_user, student, attendance_record, user_role
  features/    # onboarding / auth / home / attendance / calendar / schedule / settings / notifications / shell
  shared/      # 역할 공용 위젯 (AppScaffold 배경, 스플래시 등)
```

## 시작하기

공개 저장소라 Firebase 설정 파일은 포함되어 있지 않습니다. clone 후 재생성이 필요합니다.

```bash
git clone https://github.com/Diana-yjh/Jigeum_Yeogi.git
cd Jigeum_Yeogi
flutter pub get

# Firebase 설정 파일 생성 (프로젝트 접근 권한 필요)
dart pub global activate flutterfire_cli
flutterfire configure --project=jigeum-yeogi-25737 \
  --platforms=android,ios \
  --ios-bundle-id=com.diana.jigeumYeogi \
  --android-package-name=com.diana.jigeumYeogi

flutter run
```

검증은 `flutter analyze`(경고 0 유지)와 `flutter test`로 합니다.

## 문서

| 문서 | 내용 |
|------|------|
| [`docs/specs/`](docs/specs/README.md) | 탭별 상세 요구사항 (홈·출석·스케줄·달력·설정) |
| [`docs/Design.md`](docs/Design.md) | 디자인 시스템 — 색·타이포·컴포넌트 규칙 |
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | 개발 진행 기록 |
| [개인정보처리방침](https://diana-yjh.github.io/Jigeum_Yeogi/privacy/) | 수집 항목·삭제 절차 |
| [계정 삭제 안내](https://diana-yjh.github.io/Jigeum_Yeogi/account-deletion/) | 앱 내·이메일 삭제 경로 |

## 문의

devyjhong@gmail.com
