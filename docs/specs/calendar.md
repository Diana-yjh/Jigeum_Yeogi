# 달력 탭 (calendar) — 학부모 전용

`lib/features/calendar/parent_calendar_screen.dart`
(선생님 달력은 탭이 아니라 **출석 탭의 달력 아이콘**으로 진입 → `teacher_calendar_screen.dart`)

## 목적
내 아이의 월별 출결 기록을 시각화.

# 달력 화면 (학부모)

전제: `design/CLAUDE.md`의 토큰과 공통 컴포넌트를 쓴다.

## 목적

한 달 출석 패턴을 훑고, 특정 날짜를 눌러 "몇 시부터 몇 시까지 있었는지"를 확인한다.

## 레이아웃 (위→아래)

세로 스크롤 `ListView`. 좌우 패딩 16, 항목 간 간격 10.

1. 월 이동 헤더
2. 월간 요약 카드 2개 (가로 2열)
3. 달력 그리드 카드
4. 선택 날짜 상세 카드
5. `ParentTabBar` (달력 활성)

"출결 달력" 화면 타이틀은 삭제한다. 월 헤더가 타이틀 역할을 한다.

### 1. 월 이동 헤더

`Row(spaceBetween)`: 좌 `<` 아이콘(textSecondary) / 중 `2026년 8월` 15 / w600 / 우 `>` 아이콘.
좌우 스와이프로도 월 이동(`PageView`). 미래 달로는 이동 가능하되 데이터 없음 상태로 표시.

### 2. 월간 요약 카드

`Row`에 `Expanded` 2개, 간격 8. 각각 `AppCard(padding: h10 v8)`.
- 좌: 캡션 `이번 달 출석` 12 textSecondary / 아래 `9`(20 w600) + `회`(12 textSecondary)
- 우: 캡션 `평균 체류` / `3`(20 w600) + `시간 40분`(12 textSecondary)
- 평균 체류는 등원·하원이 모두 있는 날만 평균. 0회면 `--`.

### 3. 달력 그리드

`AppCard(padding: h6 v10)`.
- 요일 헤더 7칸, 12 textMuted. 일요일만 primary. 일요일 시작(일~토).
- 날짜 셀: 세로 `Column` — 날짜 숫자 13 + 아래 지름 4 도트, 간격 2.
  - 출석한 날: 도트 primary
  - 출석 없음: 도트 투명(레이아웃 유지용으로 그리되 색만 투명)
  - 앞뒤 달 날짜: 숫자 dividerStrong, 도트 없음
  - 선택된 날: 숫자를 지름 22 primary 원 안에 흰색 w600
  - 오늘: 선택 안 됐을 때 숫자 primary 색으로만 구분
- 기존의 "오렌지 테두리 원 + 오렌지 글자" 선택 스타일은 primary 솔리드 원으로 교체.
- 앞뒤 달 날짜 탭 시 해당 월로 이동하며 그 날짜 선택.

### 4. 선택 날짜 상세

`AppCard`. 선택 날짜에 기록이 있을 때:
- 1행: 좌 `8월 27일 목요일` 14 / w600, 우 `StatusPill('정규')` successTint / onSuccessTint 10
- 2행: 체류 타임바 Row
  - 좌 등원 시각 `12:51` 14 / w600 / primary
  - 중 `Expanded` 높이 14 트랙(divider, radius 7). 그 위에 체류 구간 막대(primaryLight, radius 7). 위치는 10:00~20:00 축 기준 비율. 축 밖 시각은 클램프.
  - 우 하원 시각 `16:41` 14 / w600 / primary. 하원 없으면 `--:--`, 막대는 등원~현재 시각.
- 3행: `Row(spaceBetween)` 12 textSecondary — `10시` / `3시간 50분 체류` / `20시`
- 축 범위(10~20시)는 상수로 두고 학원 운영시간 데이터가 생기면 그걸로 교체.

기록이 없을 때:
- 1행 날짜는 동일
- 아래 `이 날은 기록이 없어요` 14 textSecondary 한 줄. 카드 높이는 그만큼만.

기존의 "등원 ---- 하원 / 오후 12:51 / 오후 4:41 / 총 3시간 50분 체류 pill" 구조는 위로 대체한다.

## 데이터

```dart
class DayAttendance {
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String type;
}
// 월 단위 조회: Map<int /*day*/, DayAttendance>
```
월 이동 시 해당 월 데이터를 한 번에 가져와 캐시. 날짜 탭은 로컬 상태만 바꾼다(네트워크 호출 없음).

## 하지 말 것

- 시각에 `오전/오후` 접두어 쓰지 않는다. 24시간 `HH:mm`.
- 달력 셀 안에 시간 텍스트를 넣지 않는다. 도트 하나로 끝.
- 상세 카드가 그리드 아래에서 사라지지 않게 한다(초기 선택은 오늘, 오늘 기록 없으면 이번 달 마지막 출석일).

## 선생님 달력 (참고)
- 등원 있던 날 표시, 날짜 탭 → 그 날 등원한 학생 명단·시각·인원수.

## 데이터
- `childMonthRecordsProvider("yyyy-MM")`, `teacherMonthRecordsProvider(...)`
- 복합 인덱스: `(parentUid, date)`, `(teacherCode, date)`.

## 공용
- 달력 셀·요일 헤더: `lib/features/calendar/widgets/calendar_cells.dart`.
