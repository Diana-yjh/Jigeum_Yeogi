import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jigeum_yeogi/app.dart';

void main() {
  testWidgets('시작 화면에서 역할 선택 후 탭 셸로 진입한다',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JigeumYeogiApp()));

    // 시작 화면: 역할 선택 카드가 보인다.
    expect(find.text('선생님으로 시작'), findsOneWidget);
    expect(find.text('학부모로 시작'), findsOneWidget);

    // 선생님 선택 → 하단 탭(출석)이 나타난다.
    await tester.tap(find.text('선생님으로 시작'));
    await tester.pumpAndSettle();

    expect(find.text('출석'), findsWidgets);
  });
}
