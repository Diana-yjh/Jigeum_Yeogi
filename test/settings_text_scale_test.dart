// 설정 화면 — 작은 폰(iPhone SE급)에서 글씨 배율 상한(1.3)까지 넘침이 없어야 한다.
//
// 회귀 배경: 선생님 '내 정보' 카드의 값 텍스트가 Expanded 없이 놓여 있어
// 긴 이메일이 배율 1.0에서도 오른쪽으로 넘쳤다.
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

Future<void> fonts() async {
  final l = FontLoader('GmarketSans');
  for (final p in ['assets/fonts/GmarketSansLight.otf','assets/fonts/GmarketSansMedium.otf','assets/fonts/GmarketSansBold.otf']) { l.addFont(rootBundle.load(p)); }
  await l.load();
}
Widget wrap(double sys, List<dynamic> ov) => ProviderScope(overrides: ov.cast(), child: MaterialApp(theme: AppTheme.light,
  builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(sys * 1.12)), child: child!),
  home: const SettingsScreen()));

void main() {
  const sched = {'mon': ScheduleEntry(time: '15:00', type: ClassType.regular)};
  final kids = [const Student(id: 's1', name: '김테스트', teacherCode: '123456', parentUid: 'p1', schedule: sched), const Student(id: 's2', name: '박테스트', teacherCode: '123456', parentUid: 'p1', schedule: sched)];
  const parent = AppUser(uid: 'p1', role: Role.parent, name: '홍테스트', email: 'parent.test.long.address@example.com', teacherCode: '123456');
  const teacher = AppUser(uid: 't1', role: Role.teacher, name: '김선생테스트', email: 'teacher.test.long.address@example.com', teacherCode: '123456');
  for (final sys in [1.0, 1.3]) {
    for (final role in ['학부모', '선생님']) {
      testWidgets('배율 $sys / $role', (tester) async {
        await fonts();
        tester.view.physicalSize = const Size(750, 1334);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);
        final ov = role == '학부모'
          ? [appUserProvider.overrideWith((r) => Stream.value(parent)), childrenProvider.overrideWith((r) => Stream.value(kids))]
          : [appUserProvider.overrideWith((r) => Stream.value(teacher)), teacherStudentsProvider.overrideWith((r) => Stream.value(kids))];
        await tester.pumpWidget(wrap(sys, ov));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '$role 설정 화면이 배율 $sys에서 넘친다');
      });
    }
  }
}
