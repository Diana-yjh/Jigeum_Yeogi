import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';

/// 화면 공용 배경 — 웜 화이트 위에 은은한 파스텔 번짐과 옅은 도트 결.
///
/// 카드·글자 대비를 해치지 않도록 모두 아주 낮은 농도로 그린다.
/// 정적이라 [RepaintBoundary]로 감싸 다시 그리지 않는다.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(painter: _BackgroundPainter()),
        ),
        ?child,
      ],
    );
  }
}

/// 패턴 배경을 깐 Scaffold. 화면에서는 `Scaffold` 대신 이걸 쓴다.
/// 라우트 전환 중 뒤 화면이 비치지 않도록 바깥에서 불투명하게 칠한다.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1) 바탕색.
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);

    // 2) 파스텔 번짐 — 우상단 피치, 좌하단 세이지, 중앙 하단 아주 옅은 피치.
    _blob(canvas, Offset(w * 1.02, h * -0.04), w * 0.72,
        AppColors.primaryTint.withValues(alpha: 0.55));
    _blob(canvas, Offset(w * -0.18, h * 0.78), w * 0.62,
        AppColors.sageSoft.withValues(alpha: 0.85));
    _blob(canvas, Offset(w * 0.55, h * 1.06), w * 0.5,
        AppColors.primarySoft.withValues(alpha: 0.7));

    // 3) 옅은 도트 결 — 종이 질감. 촘촘하지 않게 22px 간격, 반지름 1.
    final dot = Paint()..color = AppColors.textFaint.withValues(alpha: 0.13);
    const gap = 22.0;
    for (var y = gap / 2; y < h; y += gap) {
      // 줄마다 반칸씩 어긋나게 해 격자 느낌을 줄인다.
      final shift = ((y ~/ gap).isEven) ? 0.0 : gap / 2;
      for (var x = gap / 2 + shift; x < w; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.0, dot);
      }
    }
  }

  /// 중심에서 바깥으로 사라지는 원형 그라디언트(블러 대신 — 훨씬 가볍다).
  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => false;
}
