// 학부모 홈 — 자녀가 여러 명일 때.
//
// 아이마다 하원 타임라인과 이번 주 출석이 모두 보여야 하고(예전에는 한 줄짜리
// 상태 카드만 남고 두 섹션이 사라졌다), 아이 사이는 좌우 스와이프로 넘긴다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/home/parent_home_screen.dart';
import 'package:jigeum_yeogi/features/notifications/state/notification_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';

const _schedule = {
  'mon': ScheduleEntry(time: '15:00', type: ClassType.regular),
  'wed': ScheduleEntry(time: '15:00', type: ClassType.regular),
  'fri': ScheduleEntry(time: '15:00', type: ClassType.regular),
};

Student _student(String id, String name) => Student(
      id: id,
      name: name,
      teacherCode: '123456',
      parentUid: 'p1',
      schedule: _schedule,
    );

AttendanceRecord _record(String studentId, DateTime day,
        {Duration? inAt, Duration? outAt}) =>
    AttendanceRecord(
      studentId: studentId,
      date: dateKey(day),
      teacherCode: '123456',
      parentUid: 'p1',
      checkInAt: inAt == null ? null : day.add(inAt),
      checkOutAt: outAt == null ? null : day.add(outAt),
    );

Future<void> _loadFonts() async {
  final loader = FontLoader('GmarketSans');
  for (final p in [
    'assets/fonts/GmarketSansLight.otf',
    'assets/fonts/GmarketSansMedium.otf',
    'assets/fonts/GmarketSansBold.otf',
  ]) {
    loader.addFont(rootBundle.load(p));
  }
  await loader.load();
}

void main() {
  testWidgets('자녀가 둘이면 좌우 스와이프로 넘기고, 아이마다 타임라인·주간 출석이 보인다',
      (tester) async {
    await _loadFonts();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final tuesday = monday.add(const Duration(days: 1));

    // 김테스트: 등원만(수업 중) / 박테스트: 하원까지 완료.
    final inClass = _record('s1', today, inAt: const Duration(hours: 15, minutes: 2));
    final done = _record('s2', today,
        inAt: const Duration(hours: 15, minutes: 10),
        outAt: const Duration(hours: 17, minutes: 30));

    // 주간 기록은 자녀 전체가 한 번에 온다 — 아이별로 갈라져야 한다.
    // s1은 2건, s2는 1건.
    final week = [
      _record('s1', monday, inAt: const Duration(hours: 15)),
      _record('s1', tuesday, inAt: const Duration(hours: 15)),
      _record('s2', monday, inAt: const Duration(hours: 15)),
    ];

    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith(
              (ref) => Stream.value([_student('s1', '김테스트'), _student('s2', '박테스트')])),
          childWeekRecordsProvider.overrideWith((ref) => Stream.value(week)),
          studentTodayRecordProvider.overrideWith(
              (ref, id) => Stream.value(id == 's1' ? inClass : done)),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ParentHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // ── 첫 페이지: 김테스트(수업 중) ──────────────────────────────
    expect(find.text('김테스트'), findsOneWidget);
    expect(find.text('박테스트'), findsNothing); // 한 번에 한 명씩
    expect(find.text('지금 학원에 있어요'), findsOneWidget);
    expect(find.text('15:02'), findsOneWidget); // 등원 시각
    expect(find.text('--:--'), findsOneWidget); // 아직 하원 전
    expect(find.text('이번 주 출석'), findsOneWidget);
    expect(find.text('2 / 3회'), findsOneWidget);

    // 페이지 표시 점이 자녀 수만큼.
    expect(find.byType(PageView), findsOneWidget);

    // ── 옆으로 밀면 박테스트(하원 완료) ───────────────────────────
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('박테스트'), findsOneWidget);
    expect(find.text('김테스트'), findsNothing);
    expect(find.text('집에 잘 갔어요'), findsOneWidget);
    expect(find.text('15:10'), findsOneWidget); // 등원
    expect(find.text('17:30'), findsOneWidget); // 하원
    expect(find.text('이번 주 출석'), findsOneWidget);
    // 주간 횟수는 아이별로 갈린다(형제 것이 합산되지 않는다).
    expect(find.text('1 / 3회'), findsOneWidget);
    expect(find.text('2 / 3회'), findsNothing);

    // ── 다시 오른쪽으로 밀면 첫 아이로 돌아온다 ────────────────────
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('김테스트'), findsOneWidget);
    expect(find.text('2 / 3회'), findsOneWidget);
  });
}
