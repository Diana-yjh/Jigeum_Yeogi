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

/// 날짜 숫자를 담는 원. 기본 지름 26.
///
/// 고정 크기로 두면 시스템 글씨 확대 시 두 자리 숫자가 원 밖으로 잘린다.
/// 배율에 맞춰 지름을 키우되, 7열 그리드가 유지되도록 셀 폭 안으로 제한하고
/// 그래도 부족하면 [FittedBox]로 숫자를 줄여 잘림을 막는다.
class CalendarDayNumber extends StatelessWidget {
  const CalendarDayNumber({
    super.key,
    required this.number,
    required this.style,
    this.decoration,
    this.baseDiameter = 26,
  });

  final String number;
  final TextStyle style;
  final Decoration? decoration;
  final double baseDiameter;

  /// 글씨 배율에 맞춰 커진 지름. 행 높이 계산에도 쓴다.
  static double scaledDiameter(BuildContext context, {double base = 26}) =>
      MediaQuery.textScalerOf(context).scale(base);

  @override
  Widget build(BuildContext context) {
    final wanted = scaledDiameter(context, base: baseDiameter);
    return LayoutBuilder(
      builder: (context, constraints) {
        // 셀 폭을 넘지 않는 선에서 최대한 키운다. 폭이 기본 지름보다도 좁으면
        // 폭에 맞추고, 숫자는 FittedBox가 줄여준다.
        var diameter = wanted < baseDiameter ? baseDiameter : wanted;
        if (constraints.maxWidth.isFinite && diameter > constraints.maxWidth) {
          diameter = constraints.maxWidth;
        }
        return Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: decoration,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(number, style: style, maxLines: 1),
          ),
        );
      },
    );
  }
}

/// 요일 헤더 높이. [koreanDow]가 쓰는 AppText.caption(13, height 1.3) 기준으로
/// 글씨 배율에 맞춰 커진다. [minimum]은 기본 배율에서의 기존 높이.
double calendarDowHeight(BuildContext context, {double minimum = 24}) {
  final wanted = MediaQuery.textScalerOf(context).scale(13) * 1.3 + 6;
  return wanted < minimum ? minimum : wanted;
}

/// 날짜 원이 들어갈 [TableCalendar] 행 높이. 글씨 배율에 따라 함께 커진다.
/// [extra]는 원 아래에 들어가는 요소(도트·인원수 등)의 높이,
/// [minimum]은 기본 배율에서의 기존 행 높이(더 낮아지지 않게 하는 하한).
double calendarRowHeight(
  BuildContext context, {
  double extra = 0,
  required double minimum,
}) {
  final wanted = CalendarDayNumber.scaledDiameter(context) + extra + 16;
  return wanted < minimum ? minimum : wanted;
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

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: CalendarDayNumber(
        number: '${day.day}',
        decoration: BoxDecoration(
          color: bg,
          border: border,
          shape: BoxShape.circle,
        ),
        style: AppText.body.copyWith(
          color: fg,
          fontWeight: (attended || isToday) ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ),
  );
}
