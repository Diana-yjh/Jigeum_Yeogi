// 달력 날짜 셀이 시스템 글씨 확대에도 잘리지 않는지 검증한다.
//
// 회귀 배경: 날짜 원이 26x26 고정이라 시스템 배율 1.3(앱 적용 1.46)부터
// 두 자리 숫자가 원 밖으로 잘렸다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/features/calendar/widgets/calendar_cells.dart';

/// 앱은 시스템 배율 위에 12%를 더 얹는다(app.dart).
TextScaler appScaler(double systemScale) =>
    TextScaler.linear(systemScale * 1.12);

const _systemScales = [1.0, 1.3, 1.5, 2.0, 3.0];
const _cellWidth = 52.0; // 390pt 화면에서 7열 그리드의 대략적 셀 폭

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

/// 실제 화면과 같은 구조: 셀 폭 안의 Column(가로 제약이 느슨함).
Widget _harness(TextScaler scaler) => MediaQuery(
  data: MediaQueryData(textScaler: scaler),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: _cellWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CalendarDayNumber(
              number: '28',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 14,
                color: AppColors.textMain,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('날짜 원이 글씨 배율에 따라 커지고, 어느 배율에서도 오버플로가 없다', (tester) async {
    await _loadFonts();

    var previous = 0.0;
    for (final sys in _systemScales) {
      await tester.pumpWidget(_harness(appScaler(sys)));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '시스템 배율 $sys에서 예외 발생');

      final diameter = tester.getSize(find.byType(Container).first).width;

      expect(
        diameter,
        greaterThanOrEqualTo(previous),
        reason: '배율이 커졌는데 원이 줄어들면 안 된다 (시스템 배율 $sys)',
      );
      expect(
        diameter,
        lessThanOrEqualTo(_cellWidth),
        reason: '원이 셀 폭을 넘으면 7열 그리드가 깨진다 (시스템 배율 $sys)',
      );
      previous = diameter;
    }

    // 회귀 지점: 예전에는 26 고정이라 이 배율에서 숫자(26.8pt)가 잘렸다.
    await tester.pumpWidget(_harness(appScaler(1.3)));
    await tester.pump();
    final d = tester.getSize(find.byType(Container).first).width;
    final textWidth = tester.getSize(find.text('28')).width;
    expect(d, greaterThan(26.0));
    expect(textWidth, lessThanOrEqualTo(d), reason: '숫자가 원 밖으로 나가면 안 된다');
  });

  testWidgets('셀 폭보다 원이 커질 상황에서도 FittedBox가 숫자를 줄여 잘림을 막는다', (tester) async {
    await _loadFonts();
    await tester.pumpWidget(_harness(appScaler(3.0)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsOneWidget);
    expect(
      tester.getSize(find.byType(Container).first).width,
      lessThanOrEqualTo(_cellWidth),
    );
  });

  testWidgets('달력 행 높이는 기본 배율에서 기존 값을 유지하고, 확대 시 함께 커진다', (tester) async {
    final heights = <double, double>{};
    for (final sys in [1.0, 1.5, 2.4, 3.0]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: appScaler(sys)),
          child: Builder(
            builder: (context) {
              heights[sys] = calendarRowHeight(context, minimum: 56);
              return const SizedBox();
            },
          ),
        ),
      );
    }
    expect(heights[1.0], 56.0); // 기존 모양 유지
    expect(heights[1.5]!, greaterThan(56.0));
    expect(heights[2.4]!, greaterThan(heights[1.5]!));
    expect(heights[3.0]!, greaterThan(heights[2.4]!));
  });
}
