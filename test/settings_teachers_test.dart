// 학부모 설정 — 선생님 아래 반 아이 관리 + 우리 아이는 이름당 한 번.
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

  tester.view.physicalSize = const Size(1170, 3200);
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

const _user = AppUser(
  uid: 'p1',
  role: Role.parent,
  name: '홍테스트',
  email: 'p@test.com',
  teachers: {'111111': '수학 김선생님', '222222': '피아노 이선생님'},
);

void main() {
  testWidgets('선생님 아래 반 아이들이 나열되고, 같은 이름 아이는 우리 아이에 한 번만',
      (tester) async {
    await _pump(tester, user: _user, children: [
      _child('m1', '김테스트', '111111'), // 수학
      _child('pi1', '김테스트', '222222'), // 피아노 (같은 아이)
      _child('s3', '박테스트', '111111'), // 수학
    ]);

    // 선생님 블록 아래 반 소속 아이들 + "이 반에 아이 추가" 행이 반마다.
    expect(find.byIcon(Icons.subdirectory_arrow_right), findsNWidgets(3));
    expect(find.text('이 반에 아이 추가'), findsNWidgets(2));

    // 우리 아이: 김테스트는 한 번만, 소속 닉네임이 캡션으로 합쳐진다.
    expect(find.text('수학 김선생님 · 피아노 이선생님'), findsOneWidget);
    expect(find.text('박테스트'), findsNWidgets(2)); // 반 목록 1 + 우리 아이 1
    expect(find.text('김테스트'), findsNWidgets(3)); // 반 목록 2 + 우리 아이 1
  });

  testWidgets('이 반에 아이 추가 → 기존 아이는 드롭다운으로 선택(한 번만 입력)',
      (tester) async {
    await _pump(tester, user: _user, children: [
      _child('m1', '김테스트', '111111'),
      _child('s3', '박테스트', '111111'),
    ]);

    // 피아노 반(아이 없음)의 추가 행을 탭.
    await tester.tap(find.text('이 반에 아이 추가').last);
    await tester.pumpAndSettle();

    expect(find.text('피아노 이선생님 반에 아이 추가'), findsOneWidget);
    // 기존 아이 선택 드롭다운 + 직접 입력 옵션.
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('새로운 아이 직접 입력…'), findsOneWidget);
  });
}
