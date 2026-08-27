import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';

/// 텍스트 스타일 토큰. 제목은 타이트하게(letterSpacing↓), 본문은 여유 있게(height↑).
abstract class AppText {
  static const display = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.6,
      color: AppColors.textMain);
  static const screenTitle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.4,
      color: AppColors.textMain);
  static const sectionTitle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.textMain);
  static const cardTitle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.textMain);
  static const body = TextStyle(
      fontSize: 15, height: 1.4, color: AppColors.textMain);
  static const caption = TextStyle(
      fontSize: 13, height: 1.3, color: AppColors.textSub);
}
