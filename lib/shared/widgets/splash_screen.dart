import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';

/// 인증/프로필 로딩 중 표시하는 스플래시.
class SplashScreen extends StatelessWidget {
  final String message;
  const SplashScreen({super.key, this.message = '불러오는 중...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpace.md),
            Text(message, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}
