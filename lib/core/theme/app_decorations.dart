import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';

/// 공용 데코레이션 — 소프트 파스텔 카드(둥근 모서리 + 부드러운 그림자).
abstract class AppDecoration {
  /// 흰 카드(부드러운 그림자, 테두리 없음).
  static BoxDecoration card({
    Color color = AppColors.card,
    double radius = AppRadius.card,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppShadow.soft,
    );
  }

  /// 은은한 배경 틴트 카드(그림자 없이 부드러운 색면).
  static BoxDecoration tint(
    Color color, {
    double radius = AppRadius.card,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// 그라디언트 히어로 카드. [tint]를 주면 그 색 기반 그라디언트(선생님 구분색).
  static BoxDecoration hero({double radius = AppRadius.card, Color? tint}) {
    return BoxDecoration(
      gradient:
          tint == null ? AppColors.primaryGradient : AppColors.gradientFor(tint),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppShadow.soft,
    );
  }
}
