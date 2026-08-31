// 학부모 달력 — 자녀가 여러 명이면 한 달력에 아이별 색으로 함께 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
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

/// 지름 [size]짜리 원형 도트 중 [color]인 것의 개수.
int _dots(WidgetTester tester, Color color, double size) => tester
    .widgetList<Container>(find.byType(Container))
    .where((c) {
      final d = c.decoration;
      return d is BoxDecoration &&
          d.shape == BoxShape.circle &&
          d.color == color &&
          c.constraints?.maxWidth == size;
    })
    .length;

void main() {
  testWidgets('같은 날 두 아이 기록이 색 도트로 함께 표시되고, 상세에 아이별 블록이 생긴다',
      (tester) async {
    await _loadFonts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final records = [
      _record('s1', today, 15, 2), // 김테스트 15:02 (첫째 색 = primary)
      _record('s2', today, 16, 45), // 박테스트 16:45 (둘째 색 = sageDeep)
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

    // 범례 + 요약 + 상세 → 이름이 여러 곳에 보인다(필터링 안 함).
    expect(find.text('김테스트'), findsWidgets);
    expect(find.text('박테스트'), findsWidgets);

    // 오늘 셀 아래 도트: 첫째 primary 1개, 둘째 sageDeep 1개 (지름 4).
    expect(_dots(tester, AppColors.childColor(0), 4), 1);
    expect(_dots(tester, AppColors.childColor(1), 4), 1);

    // 상세 카드에 두 아이 시각이 모두 보인다 — 한 아이가 다른 아이를 덮어쓰지 않는다.
    expect(find.text('15:02'), findsOneWidget);
    expect(find.text('16:45'), findsOneWidget);
    expect(find.text('17:02'), findsOneWidget);
    expect(find.text('18:45'), findsOneWidget);

    // 요약: 아이별 횟수 → '회' 단위가 아이 수만큼.
    expect(find.text('회'), findsNWidgets(2));
  });

  testWidgets('자녀가 한 명이면 범례 없이 기존 단일 레이아웃', (tester) async {
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

    expect(find.text('김테스트'), findsNothing); // 범례·이름 없음
    expect(find.text('15:02'), findsOneWidget);
    expect(find.text('정규'), findsOneWidget); // 날짜 옆 pill
  });
}
