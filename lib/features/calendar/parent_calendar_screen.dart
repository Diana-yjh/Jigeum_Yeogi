import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/shared/widgets/status_pill.dart';

// 체류 타임바 축(분): 10:00 ~ 20:00.
const _axisStart = 10 * 60;
const _axisEnd = 20 * 60;

/// 학부모 출결 달력 — 커스텀 그리드 + 선택 날짜 체류 상세.
class ParentCalendarScreen extends ConsumerStatefulWidget {
  const ParentCalendarScreen({super.key});

  @override
  ConsumerState<ParentCalendarScreen> createState() =>
      _ParentCalendarScreenState();
}

class _ParentCalendarScreenState extends ConsumerState<ParentCalendarScreen> {
  late DateTime _month; // 해당 월 1일
  DateTime? _selected; // null이면 자동 선택(오늘/마지막 출석일)

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selected = null; // 새 달에서 자동 선택
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(childProvider).value;
    final records =
        ref.watch(childMonthRecordsProvider(monthKey(_month))).value ??
            const [];
    final byDay = {
      for (final r in records) int.parse(r.date.split('-')[2]): r,
    };

    final selected = _selected ?? _autoSelect(byDay);
    final selRec = byDay[selected.day];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            Text('출결 달력', style: AppText.screenTitle),
            const SizedBox(height: AppSpace.md),
            _monthHeader(),
            const SizedBox(height: AppSpace.md),
            _summary(records),
            const SizedBox(height: AppSpace.md),
            GestureDetector(
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) _changeMonth(1);
                if (v > 200) _changeMonth(-1);
              },
              child: _grid(byDay, selected),
            ),
            const SizedBox(height: AppSpace.md),
            _detail(child, selected, selRec),
          ],
        ),
      ),
    );
  }

  /// 오늘(이 달일 때) 우선, 없으면 이 달 마지막 출석일, 그것도 없으면 1일.
  DateTime _autoSelect(Map<int, AttendanceRecord> byDay) {
    final now = DateTime.now();
    if (now.year == _month.year && now.month == _month.month) {
      return DateTime(_month.year, _month.month, now.day);
    }
    final attendedDays = byDay.entries
        .where((e) => e.value.isCheckedIn)
        .map((e) => e.key)
        .toList()
      ..sort();
    final day = attendedDays.isNotEmpty ? attendedDays.last : 1;
    return DateTime(_month.year, _month.month, day);
  }

  // ── 월 이동 헤더 ──
  Widget _monthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textSub),
          onPressed: () => _changeMonth(-1),
        ),
        Text('${_month.year}년 ${_month.month}월',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain)),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.textSub),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  // ── 월간 요약(이번 달 출석) ──
  Widget _summary(List<AttendanceRecord> records) {
    final count = records.where((r) => r.isCheckedIn).length;
    return _stat('이번 달 출석', '$count', '회');
  }

  Widget _stat(String caption, String value, String suffix) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDecoration.card(radius: AppRadius.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: AppText.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(suffix, style: AppText.caption.copyWith(fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── 달력 그리드 ──
  Widget _grid(Map<int, AttendanceRecord> byDay, DateTime selected) {
    const dows = ['일', '월', '화', '수', '목', '금', '토'];
    final leading = _month.weekday % 7; // 일요일 시작 기준 앞 빈칸
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((leading + daysInMonth + 6) ~/ 7);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: AppDecoration.card(),
      child: Column(
        children: [
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Center(
                    child: Text(dows[c],
                        style: AppText.caption.copyWith(
                            color: c == 0
                                ? AppColors.primary
                                : AppColors.textFaint)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _cell(r * 7 + c - leading + 1, daysInMonth, byDay,
                        selected, now),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int day, int daysInMonth, Map<int, AttendanceRecord> byDay,
      DateTime selected, DateTime now) {
    // 앞뒤 달 날짜.
    if (day < 1 || day > daysInMonth) {
      final outDate = DateTime(_month.year, _month.month, day);
      return _CellButton(
        onTap: () => setState(() {
          _month = DateTime(outDate.year, outDate.month, 1);
          _selected = outDate;
        }),
        child: _cellBody('${outDate.day}',
            numberColor: AppColors.textFaint, showDot: false),
      );
    }

    final attended = byDay[day]?.isCheckedIn == true;
    final isSelected = selected.day == day;
    final isToday = now.year == _month.year &&
        now.month == _month.month &&
        now.day == day;

    final Widget body = isSelected
        ? _cellBody('$day',
            numberColor: Colors.white, selectedCircle: true, showDot: attended)
        : _cellBody('$day',
            numberColor: isToday ? AppColors.primary : AppColors.textMain,
            showDot: attended);

    return _CellButton(
      onTap: () =>
          setState(() => _selected = DateTime(_month.year, _month.month, day)),
      child: body,
    );
  }

  Widget _cellBody(String number,
      {required Color numberColor,
      bool selectedCircle = false,
      bool showDot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: selectedCircle
                ? const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)
                : null,
            child: Text(number,
                style: TextStyle(
                    fontSize: 14,
                    color: numberColor,
                    fontWeight:
                        selectedCircle ? FontWeight.w600 : FontWeight.w400)),
          ),
          const SizedBox(height: 6),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: showDot ? AppColors.primary : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  // ── 선택 날짜 상세 ──
  Widget _detail(Student? child, DateTime date, AttendanceRecord? rec) {
    final dateText = '${date.month}월 ${date.day}일 ${weekdayLabelOf(date)}요일';

    if (rec == null || !rec.isCheckedIn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: AppDecoration.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain)),
            const SizedBox(height: AppSpace.sm),
            const Text('이 날은 기록이 없어요',
                style: TextStyle(fontSize: 14, color: AppColors.textSub)),
          ],
        ),
      );
    }

    final isMakeup =
        child?.typeOn(weekdayCodes[date.weekday - 1]) == ClassType.makeup;
    final inAt = rec.checkInAt!;
    final outAt = rec.checkOutAt;
    final end = outAt ?? DateTime.now();
    final stay = end.difference(inAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateText,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
              isMakeup ? const StatusPill.makeup() : const StatusPill.regular(),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Text(clock(inAt),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDeep)),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: _StayBar(inAt: inAt, endAt: end)),
              const SizedBox(width: AppSpace.sm),
              Text(outAt != null ? clock(outAt) : '--:--',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDeep)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_axisStart ~/ 60}시', style: AppText.caption),
              Text('${formatDuration(stay)} 체류', style: AppText.caption),
              Text('${_axisEnd ~/ 60}시', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// 셀 탭 영역.
class _CellButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CellButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: child,
    );
  }
}

/// 체류 구간 막대(10~20시 축).
class _StayBar extends StatelessWidget {
  final DateTime inAt;
  final DateTime endAt;
  const _StayBar({required this.inAt, required this.endAt});

  double _frac(DateTime t) {
    final m = t.toLocal().hour * 60 + t.toLocal().minute;
    final clamped = m.clamp(_axisStart, _axisEnd);
    return (clamped - _axisStart) / (_axisEnd - _axisStart);
  }

  @override
  Widget build(BuildContext context) {
    final left = _frac(inAt);
    final right = _frac(endAt);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final barLeft = left * w;
        final barWidth = ((right - left) * w).clamp(6.0, w);
        return SizedBox(
          height: 14,
          child: Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Positioned(
                left: barLeft,
                width: barWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
