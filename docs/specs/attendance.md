# 출석 탭 (attendance) — 선생님 전용

`lib/features/attendance/attendance_screen.dart`

## 목적
오늘 수업 학생의 등원/하원을 버튼 한 번으로 체크하고 시각을 기록.

## 화면 구성
- 상단: 날짜(`M월 D일 O요일`) + 제목 "오늘 출석" + 우측 **달력 아이콘**(→ 선생님 출결 달력)
- **필터 칩**: 전체 / 등원 / 미등원 (각 인원 수 표시). pill 형태, 선택 시 채워진 primary.
- **학생 리스트**: 각 학생 카드
  - 이름 + 아바타
  - 상태별 버튼: 등원 전 = 아웃라인 "등원", 등원함 = 채워진 primary "하원", 하원 완료/결석 예정 = 상태 pill
  - 부제: 등원/하원 시각 표시
- 빈 상태: "아직 등록된 학생이 없어요..."

## 동작
- "등원" 탭 → `checkIn`(등원 시각 자동 기록, status=present)
- "하원" 탭 → `checkOut`(하원 시각 기록)
- 결석 예정(`expected_absent`) 상태 표시(학부모가 미리 알린 경우) — 알림 입력 경로는 향후.

## 데이터
- `teacherStudentsProvider` + `teacherTodayRecordsProvider`, `AttendanceRepository.checkIn/checkOut`.
- 기록: `attendance/{studentId}_{date}` (teacherCode·parentUid·date 비정규화).

## 제약 / 향후
- 현재 **전체 학생**을 표시(스케줄 무관). → 향후 "오늘 스케줄 기준" 필터 고려(열어둠).
- 등하원 시 FCM 푸시: **미사용**(제외).
