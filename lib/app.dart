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
      home: const AppRoot(),
    );
  }
}
