import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';

/// 작은 상태 pill. filled=true면 히어로(오렌지) 위 흰 반투명 배경.
class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  /// 오렌지 히어로 카드 위에 얹는 흰 반투명 pill.
  const StatusPill.onHero(this.label, {super.key})
      : background = const Color(0x33FFFFFF),
        foreground = Colors.white;

  /// 정규(세이지) pill.
  const StatusPill.regular({super.key})
      : label = '정규',
        background = AppColors.sageSoft,
        foreground = AppColors.sageDeep;

  /// 보충(피치) pill.
  const StatusPill.makeup({super.key})
      : label = '보충',
        background = AppColors.primarySoft,
        foreground = AppColors.primaryDeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          fontSize: 11,
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
