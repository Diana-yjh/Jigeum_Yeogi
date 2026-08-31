// 학부모 달력 — 자녀가 여러 명이면 아이를 골라 그 아이의 기록만 본다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/calendar/parent_calendar_screen.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';

const _schedule = {'mon': ScheduleEntry(time: '15:00', type: ClassType.regular)};

Student _student(String id, String name) => Student(
    id: id, name: name, teacherCode: '123456', parentUid: 'p1', schedule: _schedule);

AttendanceRecord _record(String studentId, DateTime day, int hour, int minute) =>
    AttendanceRecord(
      studentId: studentId,
      date: dateKey(day),
      teacherCode: '123456',
      parentUid: 'p1',
      checkInAt: DateTime(day.year, day.month, day.day, hour, minute),
      checkOutAt: DateTime(day.year, day.month, day.day, hour + 2, minute),
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
  testWidgets('자녀 칩으로 아이를 고르면 그 아이 기록만 보이고, 상세에 이름이 붙는다',
      (tester) async {
    await _loadFonts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 같은 날(오늘) 두 아이 모두 기록 — 섞이면 한 명 것이 덮어쓴다.
    final records = [
      _record('s1', today, 15, 2), // 김테스트 15:02
      _record('s2', today, 16, 45), // 박테스트 16:45
    ];

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) =>
              Stream.value([_student('s1', '김테스트'), _student('s2', '박테스트')])),
          childMonthRecordsProvider
              .overrideWith((ref, month) => Stream.value(records)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ParentCalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 칩 두 개, 기본은 첫째.
    expect(find.text('김테스트'), findsOneWidget);
    expect(find.text('박테스트'), findsOneWidget);
    expect(find.textContaining('김테스트 · '), findsOneWidget); // 상세 카드 이름
    expect(find.text('15:02'), findsOneWidget);
    expect(find.text('16:45'), findsNothing); // 다른 아이 기록은 안 보임

    // 둘째 선택.
    await tester.tap(find.text('박테스트'));
    await tester.pumpAndSettle();

    expect(find.textContaining('박테스트 · '), findsOneWidget);
    expect(find.text('16:45'), findsOneWidget);
    expect(find.text('15:02'), findsNothing);
  });

  testWidgets('자녀가 한 명이면 칩과 이름 표시가 없다', (tester) async {
    await _loadFonts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider
              .overrideWith((ref) => Stream.value([_student('s1', '김테스트')])),
          childMonthRecordsProvider.overrideWith(
              (ref, month) => Stream.value([_record('s1', today, 15, 2)])),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ParentCalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('김테스트'), findsNothing); // 칩 없음
    expect(find.textContaining(' · '), findsNothing); // 이름 접두 없음
    expect(find.text('15:02'), findsOneWidget);
  });
}
