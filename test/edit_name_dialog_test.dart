// 이름 수정 다이얼로그 — 학부모 본인/자녀/선생님 이름 수정에 공용으로 쓴다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/features/auth/data/auth_repository.dart';
import 'package:jigeum_yeogi/features/settings/widgets/edit_name_dialog.dart';

Future<void> _open(
  WidgetTester tester, {
  required String initial,
  required Future<void> Function(String) onSubmit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => EditNameDialog(
                title: '이름 수정',
                label: '이름',
                initial: initial,
                onSubmit: onSubmit,
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('기존 이름이 채워진 채로 열린다', (tester) async {
    await _open(tester, initial: '김테스트', onSubmit: (_) async {});
    expect(find.widgetWithText(TextField, '김테스트'), findsOneWidget);
  });

  testWidgets('이름을 비우고 저장하면 저장이 호출되지 않고 안내가 뜬다', (tester) async {
    var called = false;
    await _open(tester,
        initial: '김테스트', onSubmit: (_) async => called = true);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
    expect(find.byType(EditNameDialog), findsOneWidget); // 닫히지 않는다
  });

  testWidgets('앞뒤 공백을 없앤 이름으로 저장한다', (tester) async {
    String? saved;
    await _open(tester,
        initial: '김테스트', onSubmit: (name) async => saved = name);

    await tester.enterText(find.byType(TextField), '  박테스트  ');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(saved, '박테스트');
    expect(find.byType(EditNameDialog), findsNothing); // 닫힌다
  });

  testWidgets('바뀐 게 없으면 저장하지 않고 닫는다', (tester) async {
    var called = false;
    await _open(tester,
        initial: '김테스트', onSubmit: (_) async => called = true);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.byType(EditNameDialog), findsNothing);
  });

  testWidgets('저장이 실패하면 사유를 보여주고 다이얼로그는 열려 있다', (tester) async {
    await _open(tester,
        initial: '김테스트',
        onSubmit: (_) async => throw const AuthFailure('권한이 없어요.'));

    await tester.enterText(find.byType(TextField), '박테스트');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('권한이 없어요.'), findsOneWidget);
    expect(find.byType(EditNameDialog), findsOneWidget);
  });

  testWidgets('알 수 없는 오류도 안내 문구로 보여준다', (tester) async {
    await _open(tester,
        initial: '김테스트', onSubmit: (_) async => throw Exception('boom'));

    await tester.enterText(find.byType(TextField), '박테스트');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('수정 중 문제가 발생했어요.'), findsOneWidget);
    expect(find.byType(EditNameDialog), findsOneWidget);
  });
}
