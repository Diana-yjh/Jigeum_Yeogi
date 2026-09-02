// 학부모 설정 — 여러 선생님 연결 + 닉네임.
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

const _schedule = {'mon': ScheduleEntry(time: '15:00', type: ClassType.regular)};

Student _child(String id, String name, String code) => Student(
    id: id, name: name, teacherCode: code, parentUid: 'p1', schedule: _schedule);

Future<void> _pump(WidgetTester tester,
    {required AppUser user, required List<Student> children}) async {
  final loader = FontLoader('GmarketSans');
  for (final p in [
    'assets/fonts/GmarketSansLight.otf',
    'assets/fonts/GmarketSansMedium.otf',
    'assets/fonts/GmarketSansBold.otf',
  ]) {
    loader.addFont(rootBundle.load(p));
  }
  await loader.load();

  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUserProvider.overrideWith((ref) => Stream.value(user)),
        childrenProvider.overrideWith((ref) => Stream.value(children)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('선생님 여럿: 닉네임 목록·자녀 옆 소속 캡션·아이 추가에 드롭다운', (tester) async {
    const user = AppUser(
      uid: 'p1',
      role: Role.parent,
      name: '홍테스트',
      email: 'p@test.com',
      teachers: {'111111': '수학 김선생님', '222222': '피아노 이선생님'},
    );
    await _pump(tester, user: user, children: [
      _child('s1', '김테스트', '111111'),
      _child('s2', '박테스트', '222222'),
    ]);

    // 선생님 섹션 — 닉네임과 코드가 모두 보인다.
    expect(find.text('수학 김선생님'), findsWidgets);
    expect(find.text('피아노 이선생님'), findsWidgets);
    expect(find.text('111111'), findsOneWidget);
    expect(find.text('222222'), findsOneWidget);
    expect(find.text('선생님 추가'), findsOneWidget);

    // 자녀 행에 소속 선생님 닉네임 캡션.
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('김테스트')),
      findsOneWidget,
    );

    // 아이 추가 → 선생님 드롭다운.
    await tester.tap(find.text('아이 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('수학 김선생님 (111111)'), findsOneWidget);
  });

  testWidgets('선생님 하나(구버전 계정): 파생 목록 + 아이 추가는 드롭다운 없이 캡션', (tester) async {
    // teachers 맵 없이 teacherCode만 있는 기존 계정.
    const user = AppUser(
      uid: 'p1',
      role: Role.parent,
      name: '홍테스트',
      email: 'p@test.com',
      teacherCode: '374512',
    );
    await _pump(tester, user: user, children: [_child('s1', '김테스트', '374512')]);

    // 파생된 기본 닉네임과 코드.
    // '선생님' 텍스트 = 섹션 라벨 + 파생된 기본 닉네임 행, 정확히 2개.
    expect(find.text('선생님'), findsNWidgets(2));
    expect(find.text('374512'), findsOneWidget);

    // 자녀 행에는 캡션 없음(선생님 하나).
    await tester.tap(find.text('아이 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.textContaining('코드 374512'), findsOneWidget);
  });
}
