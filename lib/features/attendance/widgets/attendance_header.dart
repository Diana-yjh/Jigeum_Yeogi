import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';

/// 출석 화면 상단 헤더: 날짜 + 반 이름/출석 타이틀.
class AttendanceHeader extends StatelessWidget {
  final String dateLabel;
  final String title;

  const AttendanceHeader({
    super.key,
    required this.dateLabel,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateLabel, style: AppText.caption),
        const SizedBox(height: AppSpace.xs),
        Text(title, style: AppText.screenTitle),
      ],
    );
  }
}
