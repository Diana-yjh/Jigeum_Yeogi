import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/shared/widgets/app_background.dart';

/// 후속 Phase에서 채워질 화면용 공용 더미 위젯.
class PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const PlaceholderScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primaryDeep, size: 32),
                ),
                const SizedBox(height: AppSpace.md),
                Text(title, style: AppText.sectionTitle),
                const SizedBox(height: AppSpace.xs),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
