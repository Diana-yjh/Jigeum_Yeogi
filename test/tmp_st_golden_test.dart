import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/features/settings/settings_screen.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

void main() {
  testWidgets('g', (tester) async {
    final l = FontLoader('GmarketSans'); for (final p in ['assets/fonts/GmarketSansLight.otf','assets/fonts/GmarketSansMedium.otf','assets/fonts/GmarketSansBold.otf']) { l.addFont(rootBundle.load(p)); } await l.load();
    final mi = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')); await mi.load();
    const sched = {'mon': ScheduleEntry(time: '15:00', type: ClassType.regular)};
    const user = AppUser(uid: 'p1', role: Role.parent, name: '홍테스트', email: 'p@test.com',
        teachers: {'111111': '수학 김선생님', '222222': '피아노 이선생님'},
        teacherColors: {'222222': 0xFF4E8F87});
    final kids = [
      const Student(id: 'm1', name: '김테스트', teacherCode: '111111', parentUid: 'p1', schedule: sched),
      const Student(id: 'pi1', name: '김테스트', teacherCode: '222222', parentUid: 'p1', schedule: sched),
      const Student(id: 's3', name: '박테스트', teacherCode: '111111', parentUid: 'p1', schedule: sched),
    ];
    tester.view.physicalSize = const Size(1170, 3200); tester.view.devicePixelRatio = 3.0; addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(overrides: [
      appUserProvider.overrideWith((r) => Stream.value(user)),
      childrenProvider.overrideWith((r) => Stream.value(kids)),
    ], child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen())));
    await tester.pumpAndSettle();
    await expectLater(find.byType(SettingsScreen), matchesGoldenFile('tmp_st.png'));
  });
}
