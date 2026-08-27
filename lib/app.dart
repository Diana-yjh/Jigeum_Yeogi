import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/router/app_root.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';

/// 앱 루트 위젯. 테마 적용 + 역할 분기 라우팅 진입점.
class JigeumYeogiApp extends StatelessWidget {
  const JigeumYeogiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지금여기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 글씨를 전체적으로 키운다(시스템 접근성 배율 위에 12% 기본 확대).
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(mq.textScaler.scale(1.12)),
          ),
          child: child!,
        );
      },
      home: const AppRoot(),
    );
  }
}
