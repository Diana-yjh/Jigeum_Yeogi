import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/router/app_root.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';

/// 앱 기본 글씨 확대 배율(시스템 배율 위에 곱해진다).
const _baseTextScale = 1.12;

/// 허용하는 시스템 글씨 배율 범위. 최대 1.3 × 1.12 ≈ 1.46 까지 커진다.
const _minSystemTextScale = 0.9;
const _maxSystemTextScale = 1.3;

/// 앱 루트 위젯. 테마 적용 + 역할 분기 라우팅 진입점.
class JigeumYeogiApp extends StatelessWidget {
  const JigeumYeogiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘출석',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 글씨를 전체적으로 키운다(시스템 접근성 배율 위에 12% 기본 확대).
      // 시스템 배율은 0.9~1.3으로 제한 — 그 이상은 카드·달력 레이아웃이 넘친다.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final system = mq.textScaler.clamp(
          minScaleFactor: _minSystemTextScale,
          maxScaleFactor: _maxSystemTextScale,
        );
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(system.scale(_baseTextScale)),
          ),
          child: child!,
        );
      },
      home: const AppRoot(),
    );
  }
}
