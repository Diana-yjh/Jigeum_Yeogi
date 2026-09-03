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

void main() {
  testWidgets('g', (tester) async {
    final l = FontLoader('GmarketSans'); for (final p in ['assets/fonts/GmarketSansLight.otf','assets/fonts/GmarketSansMedium.otf','assets/fonts/GmarketSansBold.otf']) { l.addFont(rootBundle.load(p)); } await l.load();
    const math = Student(id: 'm1', name: '김테스트', teacherCode: '111111', parentUid: 'p',
        schedule: {'mon': ScheduleEntry(time: '15:00', type: ClassType.regular), 'wed': ScheduleEntry(time: '15:00', type: ClassType.regular), 'fri': ScheduleEntry(time: '15:00', type: ClassType.regular)});
    const piano = Student(id: 'pi1', name: '김테스트', teacherCode: '222222', parentUid: 'p',
        schedule: {'mon': ScheduleEntry(time: '17:00', type: ClassType.regular)});
    const other = Student(id: 's3', name: '박테스트', teacherCode: '111111', parentUid: 'p',
        schedule: {'mon': ScheduleEntry(time: '15:00', type: ClassType.regular)});
    const user = AppUser(uid: 'p', role: Role.parent, name: '홍', email: 'p@t.com',
        teachers: {'111111': '수학 김선생님', '222222': '피아노 이선생님'},
        teacherColors: {'222222': 0xFF4E8F87});
    final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day);
    final rec = AttendanceRecord(studentId: 'm1', date: dateKey(today), teacherCode: '111111', parentUid: 'p', checkInAt: today.add(const Duration(hours: 15, minutes: 2)));
    tester.view.physicalSize = const Size(1170, 2532); tester.view.devicePixelRatio = 3.0; addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(overrides: [
      appUserProvider.overrideWith((r) => Stream.value(user)),
      childrenProvider.overrideWith((r) => Stream.value([math, piano, other])),
      childWeekRecordsProvider.overrideWith((r) => Stream.value([rec])),
      studentTodayRecordProvider.overrideWith((r, id) => Stream.value(id == 'm1' ? rec : null)),
      unreadNotificationCountProvider.overrideWith((r) => 0),
    ], child: MaterialApp(theme: AppTheme.light, home: const ParentHomeScreen())));
    await tester.pumpAndSettle();
    await expectLater(find.byType(ParentHomeScreen), matchesGoldenFile('tmp_pg1.png'));
  });
}
