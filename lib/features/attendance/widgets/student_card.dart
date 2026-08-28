import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/features/attendance/models/attendance_student.dart';

/// 학생 한 명의 출석 카드.
/// 이름 + 상태 뱃지 + 등원/하원 버튼(더미).
/// 등원 완료 = 채워진 primary, 미체크 = 아웃라인.
class StudentCard extends StatelessWidget {
  final AttendanceStudent student;
  final VoidCallback? onTapAction;

  /// 오늘 출석 예정이 아닌 학생 → 회색 처리.
  final bool dimmed;

  const StudentCard({
    super.key,
    required this.student,
    this.onTapAction,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = dimmed ? AppColors.textFaint : AppColors.textMain;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: dimmed
          ? BoxDecoration(
              color: AppColors.chipNeutral,
              borderRadius: BorderRadius.circular(AppRadius.card),
            )
          : AppDecoration.card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                dimmed ? AppColors.cardBorder : AppColors.primarySoft,
            child: Text(
              student.name.characters.first,
              style: AppText.cardTitle.copyWith(
                  color: dimmed ? AppColors.textFaint : AppColors.primaryDeep),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: AppText.cardTitle.copyWith(color: nameColor)),
                const SizedBox(height: 2),
                Text(dimmed ? '오늘 예정 아님' : _subtitle(),
                    style: AppText.caption),
              ],
            ),
          ),
          _actionButton(),
        ],
      ),
    );
  }

  String _subtitle() {
    switch (student.state) {
      case CheckState.pending:
        return '아직 등원 전이에요';
      case CheckState.checkedIn:
        return '${student.checkInAt} 등원 · 수업 중';
      case CheckState.checkedOut:
        return '${student.checkInAt} 등원 → ${student.checkOutAt} 하원';
      case CheckState.expectedAbsent:
        return '오늘 결석 예정이에요';
    }
  }

  Widget _actionButton() {
    switch (student.state) {
      case CheckState.pending:
        // 오늘 예정이 아니면 등원 버튼 비활성화.
        return OutlinedButton(
          onPressed: dimmed ? null : onTapAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDeep,
            disabledForegroundColor: AppColors.textFaint,
            side: BorderSide(
                color: dimmed ? AppColors.cardBorder : AppColors.primary),
            shape: const StadiumBorder(),
          ),
          child: const Text('등원'),
        );
      case CheckState.checkedIn:
        return FilledButton(
          onPressed: onTapAction,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const StadiumBorder(),
          ),
          child: const Text('하원'),
        );
      case CheckState.checkedOut:
        return const _StatusPill(label: '완료', color: AppColors.primarySoft);
      case CheckState.expectedAbsent:
        return const _StatusPill(label: '결석 예정', color: AppColors.chipNeutral);
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: AppColors.textMain),
      ),
    );
  }
}
