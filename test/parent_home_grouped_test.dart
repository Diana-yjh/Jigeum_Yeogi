// 한 아이가 여러 선생님에게 배우는 경우 — 같은 이름의 수강을 한 페이지로 묶는다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/features/home/parent_home_screen.dart';
import 'package:jigeum_yeogi/features/notifications/state/notification_providers.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

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
  testWidgets('같은 이름 두 수강 → 한 페이지에 선생님별 카드 2개 + 선생님별 주간 요약',
      (tester) async {
    await _loadFonts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 김테스트가 수학(월·수·금)과 피아노(월) 두 선생님에게 배운다.
    const math = Student(
        id: 'm1',
        name: '김테스트',
        teacherCode: '111111',
        parentUid: 'p1',
        schedule: {
          'mon': ScheduleEntry(time: '15:00', type: ClassType.regular),
          'wed': ScheduleEntry(time: '15:00', type: ClassType.regular),
          'fri': ScheduleEntry(time: '15:00', type: ClassType.regular),
        });
    const piano = Student(
        id: 'pi1',
        name: '김테스트',
        teacherCode: '222222',
        parentUid: 'p1',
        schedule: {
          'mon': ScheduleEntry(time: '17:00', type: ClassType.regular),
        });
    const user = AppUser(
      uid: 'p1',
      role: Role.parent,
      name: '홍테스트',
      email: 'p@test.com',
      teachers: {'111111': '수학 김선생님', '222222': '피아노 이선생님'},
    );

    final mathToday = AttendanceRecord(
        studentId: 'm1',
        date: dateKey(today),
        teacherCode: '111111',
        parentUid: 'p1',
        checkInAt: today.add(const Duration(hours: 15, minutes: 2)));

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUserProvider.overrideWith((r) => Stream.value(user)),
          childrenProvider.overrideWith((r) => Stream.value([math, piano])),
          childWeekRecordsProvider
              .overrideWith((r) => Stream.value([mathToday])),
          studentTodayRecordProvider.overrideWith(
              (r, id) => Stream.value(id == 'm1' ? mathToday : null)),
          unreadNotificationCountProvider.overrideWith((r) => 0),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ParentHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 한 아이 = 한 그룹 → 헤더에 이름, 페이지 안 중복 이름 없음.
    expect(find.text('김테스트'), findsOneWidget);

    // 선생님별 칩 + 주간 요약에 닉네임이 각각 → 2개씩.
    expect(find.text('수학 김선생님'), findsNWidgets(2));
    expect(find.text('피아노 이선생님'), findsNWidgets(2));
    expect(find.text('지금 학원에 있어요'), findsOneWidget);
    expect(find.text('아직 등원 전이에요'), findsOneWidget);

    // 선생님별 주간 요약 — 수학 1/3, 피아노 0/1.
    expect(find.text('이번 주 출석'), findsOneWidget);
    expect(find.text('1 / 3회'), findsOneWidget);
    expect(find.text('0 / 1회'), findsOneWidget);

    // 그룹이 하나뿐이면 페이지 점은 없다.
    expect(find.byType(PageView), findsOneWidget);
  });
}
