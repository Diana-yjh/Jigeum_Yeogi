// 학부모 홈 '이번 주 출석' 카드 — 원은 수업일에만, 채워진 원은 출석뿐.
//
// 회귀 배경: 스케줄이 월·수·금인 아이가 이번 주 기록이 없는데도
// "월요일이 체크된 것처럼" 보였다. 지난 수업일을 회색으로 꽉 채운 원(—)으로
// 그리고, 수업 없는 오늘(화)에도 테두리 원을 그려 원이 4개가 됐기 때문.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/features/home/parent_home_screen.dart';
import 'package:jigeum_yeogi/features/notifications/state/notification_providers.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/user_role.dart';
import 'package:jigeum_yeogi/models/student.dart';

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

/// 지름 30 원 중 [bg] 배경(또는 테두리만)인 것의 개수.
int _circles(WidgetTester tester, {Color? bg, bool bordered = false}) =>
    tester.widgetList<Container>(find.byType(Container)).where((c) {
      final d = c.decoration;
      if (d is! BoxDecoration || d.shape != BoxShape.circle) return false;
      if (c.constraints?.maxWidth != 30) return false;
      if (bg != null) return d.color == bg;
      return bordered && d.border != null && d.color == null;
    }).length;

void main() {
  testWidgets('기록 없는 주: 체크 없음, 원 개수 = 수업 횟수, 지난 수업일은 ×', (tester) async {
    await _loadFonts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 오늘 요일을 뺀 세 요일에 수업 → 오늘은 수업 없는 날.
    const all = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final todayCode = all[today.weekday - 1];
    final days = all.where((d) => d != todayCode).take(3).toList();
    final schedule = {
      for (final d in days)
        d: const ScheduleEntry(time: '15:00', type: ClassType.regular),
    };
    final child = Student(
        id: 's1', name: '김테스트', teacherCode: '1', parentUid: 'p', schedule: schedule);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appUserProvider.overrideWith((r) => Stream.value(const AppUser(
            uid: 'p1', role: Role.parent, name: '홍테스트', email: 'p@test.com'))),
        childrenProvider.overrideWith((r) => Stream.value([child])),
        childProvider.overrideWith((r) => Stream.value(child)),
        childTodayRecordProvider.overrideWith((r) => Stream.value(null)),
        childWeekRecordsProvider
            .overrideWith((r) => Stream.value(const <AttendanceRecord>[])),
        unreadNotificationCountProvider.overrideWith((r) => 0),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const ParentHomeScreen()),
    ));
    await tester.pumpAndSettle();

    // 채워진 원(출석) 없음, 체크 아이콘 없음.
    expect(_circles(tester, bg: AppColors.primary), 0);
    expect(find.byIcon(Icons.check), findsNothing);

    // 원은 수업일 3개뿐 — 오늘(수업 없음)엔 원이 없다.
    expect(_circles(tester, bordered: true), 3);

    // 지난 수업일 수만큼 ×.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final pastScheduled = List.generate(7, (i) => monday.add(Duration(days: i)))
        .where((d) => d.isBefore(today) && days.contains(all[d.weekday - 1]))
        .length;
    expect(find.byIcon(Icons.close), findsNWidgets(pastScheduled));

    expect(find.text('0 / 3회'), findsOneWidget);
  });
}
