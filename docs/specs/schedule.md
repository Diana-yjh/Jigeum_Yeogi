# 스케줄 탭 (schedule) — 선생님 전용

`lib/features/schedule/schedule_screen.dart`, `student_schedule_screen.dart`

## 목적
학생별 **매주 반복** 수업 스케줄을 짜고, 오늘 등원 예정 아이를 자동 산출.

## 데이터 모델
- `students.schedule`: 요일 코드 → `{ time: "HH:mm", type: "regular"|"makeup" }`
  - 예: `{ 'mon': {time:'15:00', type:'regular'}, 'sat': {time:'14:00', type:'makeup'} }`
- `scheduledDays`(요일 키 배열)도 함께 저장(호환).
- 레거시(문자열/배열)는 자동으로 "정규"로 읽음.

## 화면 구성
상단: "오늘(O) 등원 예정 N명" 요약 + 세그먼트 `[학생별 설정] [월간 보기]`

### 학생별 설정
- 학생 목록. 각 행: 이름 + 스케줄 요약(`월·수·금`), 보충 있으면 "보충 포함" 태그, `>`
- 학생 탭 → **학생 스케줄 상세 화면**(별도 라우트):
  - 우상단 휴지통 = **학생 삭제**. 확인 다이얼로그에 "학부모 앱에서도 사라지고 출결 기록도 삭제됨"을 명시. 삭제는 `authRepository.deleteChild`(학부모와 같은 경로, 기록 정리는 onStudentDelete).
  - 요일(월~일)마다: 스위치(포함/제외), 시간 드롭다운(**08:00~22:00, 30분 단위**), **정규/보충** 칩
  - 하단 **저장** 버튼(로컬 편집 후 한 번에 저장)

### 월간 보기
- 달력: 등원 예정 있는 날 표시. 날짜 탭 → 그 요일 등원 예정 명단(시간·보충 표시, 시간순).

## 데이터/Provider
- `teacherStudentsProvider`, `todayScheduledStudentsProvider`, `scheduledOnProvider(weekdayCode)`
- `ScheduleRepository.setSchedule(studentId, Map<String, ScheduleEntry>)`

## 규칙
- "오늘 등원해야 하는 아이" = 오늘 요일이 `schedule` 키에 있는 학생. 홈·출석의 예정 계산 근거.
- 보안 규칙상 선생님은 자기 코드 소속 학생만 수정 가능.
