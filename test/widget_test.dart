import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jigeum_yeogi/features/onboarding/role_select_screen.dart';

void main() {
  // Firebase 초기화가 필요한 전체 앱 대신, 시작 화면 흐름만 검증한다.
  testWidgets('시작 화면에서 역할 선택 시 인증 화면으로 이동한다',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RoleSelectScreen()),
      ),
    );

    // 역할 선택 카드가 보인다.
    expect(find.text('선생님으로 시작'), findsOneWidget);
    expect(find.text('학부모로 시작'), findsOneWidget);

    // 선생님 선택 → 선생님 회원가입 화면으로 이동.
    await tester.tap(find.text('선생님으로 시작'));
    await tester.pumpAndSettle();

    expect(find.text('선생님 회원가입'), findsOneWidget);
    expect(find.text('가입하고 시작하기'), findsOneWidget);
  });
}
