import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';

const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

/// 요일 헤더(한글).
Widget koreanDow(DateTime day) {
  final name = _weekdayNames[day.weekday - 1];
  final isSun = day.weekday == DateTime.sunday;
  final isSat = day.weekday == DateTime.saturday;
  return Center(
    child: Text(
      name,
      style: AppText.caption.copyWith(
        color: isSun
            ? AppColors.primaryDeep
            : isSat
                ? AppColors.textSub
                : AppColors.textSub,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// 달력 날짜 셀.
/// - 오늘: 진한 오렌지 채움
/// - 선택: 오렌지 테두리
/// - 등원한 날: 연한 오렌지 채움
Widget attendanceCell(
  DateTime day, {
  bool attended = false,
  bool isToday = false,
  bool isSelected = false,
}) {
  Color bg = Colors.transparent;
  Color fg = AppColors.textMain;
  BoxBorder? border;

  if (attended) {
    bg = AppColors.primarySoft;
    fg = AppColors.primaryDeep;
  }
  if (isToday) {
    bg = AppColors.primaryDeep;
    fg = Colors.white;
  }
  if (isSelected && !isToday) {
    border = Border.all(color: AppColors.primary, width: 1.5);
    fg = AppColors.primaryDeep;
  }

  return Container(
    margin: const EdgeInsets.all(4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      border: border,
      shape: BoxShape.circle,
    ),
    child: Text(
      '${day.day}',
      style: AppText.body.copyWith(
        color: fg,
        fontWeight: (attended || isToday) ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}
