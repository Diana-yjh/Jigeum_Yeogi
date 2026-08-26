import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/features/attendance/models/attendance_types.dart';

/// 출석 필터 칩: 전체 / 등원 / 미등원 (각 인원 수 표시).
class AttendanceFilter extends StatelessWidget {
  final AttendanceTypes selected;
  final int allCount;
  final int presentCount;
  final int absentCount;
  final ValueChanged<AttendanceTypes> onChanged;

  const AttendanceFilter({
    super.key,
    required this.selected,
    required this.allCount,
    required this.presentCount,
    required this.absentCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('전체', allCount, AttendanceTypes.all),
        const SizedBox(width: AppSpace.sm),
        _chip('등원', presentCount, AttendanceTypes.present),
        const SizedBox(width: AppSpace.sm),
        _chip('미등원', absentCount, AttendanceTypes.absent),
      ],
    );
  }

  Widget _chip(String label, int count, AttendanceTypes type) {
    final bool isSelected = (selected == type);

    return GestureDetector(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSub,
          ),
        ),
      ),
    );
  }
}
