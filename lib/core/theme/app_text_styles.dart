import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';

/// 텍스트 스타일 토큰.
abstract class AppText {
  static const screenTitle =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textMain);
  static const sectionTitle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain);
  static const cardTitle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain);
  static const body =
      TextStyle(fontSize: 14, color: AppColors.textMain);
  static const caption =
      TextStyle(fontSize: 13, color: AppColors.textSub);
}
