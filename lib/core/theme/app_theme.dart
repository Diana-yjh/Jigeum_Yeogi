import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';

/// 앱 전역 테마. seed 컬러 기반 ColorScheme + 디자인 토큰 오버라이드.
abstract class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'GmarketSans', // 앱 전역 폰트
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        titleLarge: AppText.screenTitle,
        titleMedium: AppText.cardTitle,
        bodyMedium: AppText.body,
        bodySmall: AppText.caption,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 6,
        shadowColor: const Color(0x14453121),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primarySoft,
        elevation: 0,
        height: 66,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
            AppText.caption.copyWith(fontWeight: FontWeight.w600)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryDeep
                  : AppColors.textFaint,
            )),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
