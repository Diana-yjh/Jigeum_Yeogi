import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';

/// 화면 공용 배경 — 웜 화이트 위에 은은한 파스텔 번짐과 테라조 조각.
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

    // 3) 테라조 조각.
    _terrazzo(canvas, w, h);
  }

  /// 테라조 — 피치·세이지·모래색 조각을 크기·각도 제각각으로 흩뿌린다.
  /// 고정 시드 난수라 기기·실행마다 같은 배치가 나온다.
  void _terrazzo(Canvas canvas, double w, double h) {
    final rnd = _Rand(7);
    final colors = [
      AppColors.primaryTint.withValues(alpha: 0.55),
      AppColors.sageSoft.withValues(alpha: 0.9),
      AppColors.chipNeutral.withValues(alpha: 0.9),
      AppColors.primarySoft.withValues(alpha: 0.8),
    ];
    final n = (w * h / 5200).round(); // 화면 크기에 비례
    for (var i = 0; i < n; i++) {
      final c = Offset(rnd.next() * w, rnd.next() * h);
      final r = 3 + rnd.next() * 7;
      final paint = Paint()..color = colors[(rnd.next() * colors.length).floor()];
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rnd.next() * 6.283);
      // 살짝 찌그러진 다각형 조각
      final path = Path();
      final k = 4 + (rnd.next() * 3).floor();
      for (var j = 0; j < k; j++) {
        final a = 6.283 * j / k;
        final rr = r * (0.7 + rnd.next() * 0.6);
        final pt = Offset(rr * _cos(a), rr * _sin(a));
        j == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
      canvas.restore();
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

/// 고정 시드 선형합동 난수 — 매 프레임·매 기기에서 같은 배치를 보장한다.
class _Rand {
  _Rand(int seed) : _s = seed;
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}

double _cos(double a) => math.cos(a);
double _sin(double a) => math.sin(a);
