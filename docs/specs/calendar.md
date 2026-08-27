# 달력 탭 (calendar) — 학부모 전용

`lib/features/calendar/parent_calendar_screen.dart`
(선생님 달력은 탭이 아니라 **출석 탭의 달력 아이콘**으로 진입 → `teacher_calendar_screen.dart`)

## 목적
내 아이의 월별 출결 기록을 시각화.

## 화면 구성 (학부모)
- 제목 "출결 달력" + `table_calendar` 월 달력
  - 한글 요일 헤더, 제목 `yyyy년 M월`
  - **등원한 날 = 연한 오렌지 칩**, **오늘 = 진한 오렌지**, 선택 = 오렌지 테두리
- 날짜 탭 → **상세 카드**:
  - 등원 → 하원 **타임라인**(시각)
  - **총 체류 시간** 칩
  - **"평소보다 N분 늦게/일찍 하원"** — 그 달 평균 하원 시각 대비(기록 2개 이상일 때만)
  - 기록 없으면 "이 날은 등원 기록이 없어요."
- 월 이동 시 해당 월 데이터로 갱신.

## 선생님 달력 (참고)
- 등원 있던 날 표시, 날짜 탭 → 그 날 등원한 학생 명단·시각·인원수.

## 데이터
- `childMonthRecordsProvider("yyyy-MM")`, `teacherMonthRecordsProvider(...)`
- 복합 인덱스: `(parentUid, date)`, `(teacherCode, date)`.

## 공용
- 달력 셀·요일 헤더: `lib/features/calendar/widgets/calendar_cells.dart`.
