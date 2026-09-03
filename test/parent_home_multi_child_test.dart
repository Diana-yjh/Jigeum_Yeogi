// 학부모 홈 — 아이(이름 그룹)별 좌우 스와이프, 아이 안에서는 수강별로 항상 펼쳐진 리스트.
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

const _threeDays = {
  'mon': ScheduleEntry(time: '15:00', type: ClassType.regular),
  'wed': ScheduleEntry(time: '15:00', type: ClassType.regular),
  'fri': ScheduleEntry(time: '15:00', type: ClassType.regular),
};
const _oneDay = {'mon': ScheduleEntry(time: '17:00', type: ClassType.regular)};

const _user = AppUser(
  uid: 'p1',
  role: Role.parent,
  name: '홍테스트',
  email: 'p@test.com',
  teachers: {'111111': '수학 김선생님', '222222': '피아노 이선생님'},
);

Student _s(String id, String name, String code, Map<String, ScheduleEntry> sched) =>
    Student(id: id, name: name, teacherCode: code, parentUid: 'p1', schedule: sched);

AttendanceRecord _rec(String id, String code, DateTime day,
        {int h = 15, bool out = false}) =>
    AttendanceRecord(
      studentId: id,
      date: dateKey(day),
      teacherCode: code,
      parentUid: 'p1',
      checkInAt: DateTime(day.year, day.month, day.day, h, 2),
      checkOutAt: out ? DateTime(day.year, day.month, day.day, h + 2, 30) : null,
    );

Future<void> _pump(WidgetTester tester,
    {required List<Student> children,
    required List<AttendanceRecord> week,
    required Map<String, AttendanceRecord?> today}) async {
  final loader = FontLoader('GmarketSans');
  for (final p in [
    'assets/fonts/GmarketSansLight.otf',
    'assets/fonts/GmarketSansMedium.otf',
    'assets/fonts/GmarketSansBold.otf',
  ]) {
    loader.addFont(rootBundle.load(p));
  }
  await loader.load();

  tester.view.physicalSize = const Size(1170, 3200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUserProvider.overrideWith((r) => Stream.value(_user)),
        childrenProvider.overrideWith((r) => Stream.value(children)),
        childWeekRecordsProvider.overrideWith((r) => Stream.value(week)),
        studentTodayRecordProvider
            .overrideWith((r, id) => Stream.value(today[id])),
        unreadNotificationCountProvider.overrideWith((r) => 0),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const ParentHomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('아이 둘 → 좌우 스와이프, 페이지마다 그 아이 것만', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final kim = _rec('s1', '111111', today);
    final park = _rec('s2', '111111', today, out: true);
    await _pump(tester,
        children: [
          _s('s1', '김테스트', '111111', _threeDays),
          _s('s2', '박테스트', '111111', _threeDays),
        ],
        week: [kim, park, _rec('s1', '111111', monday)],
        today: {'s1': kim, 's2': park});

    // 페이저 — 첫 페이지엔 김테스트만.
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('김테스트'), findsOneWidget);
    expect(find.text('박테스트'), findsNothing);
    expect(find.text('이번 주 출석'), findsOneWidget);

    // 옆으로 밀면 박테스트 — 주간 값이 그 아이 것으로 갈린다.
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('박테스트'), findsOneWidget);
    expect(find.text('김테스트'), findsNothing);
    expect(find.text('1 / 3회'), findsOneWidget);
  });

  testWidgets('한 아이 두 수강 → 한 페이지에 접히지 않는 리스트(히어로·주간 카드 각각)',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final math = _rec('m1', '111111', today);
    await _pump(tester,
        children: [
          _s('m1', '김테스트', '111111', _threeDays),
          _s('pi1', '김테스트', '222222', _oneDay),
        ],
        week: [math],
        today: {'m1': math, 'pi1': null});

    // 그룹이 하나 → 헤더에 아이 이름, 페이지 안 이름 중복 없음.
    expect(find.text('김테스트'), findsOneWidget);

    // 수강별 칩 + 히어로 + 주간 카드가 모두 "펼쳐진 채" 보인다.
    expect(find.text('수학 김선생님'), findsOneWidget);
    expect(find.text('피아노 이선생님'), findsOneWidget);
    expect(find.text('지금 학원에 있어요'), findsOneWidget);
    expect(find.text('아직 등원 전이에요'), findsOneWidget);
    expect(find.text('이번 주 출석'), findsNWidgets(2));
    expect(find.text('1 / 3회'), findsOneWidget);
    expect(find.text('0 / 1회'), findsOneWidget);
  });
}
