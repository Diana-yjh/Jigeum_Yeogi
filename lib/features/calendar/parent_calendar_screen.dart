import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/calendar/widgets/calendar_cells.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';

/// 학부모 출결 달력 — 등원한 날 칩, 오늘 강조, 날짜 탭 시 상세.
class ParentCalendarScreen extends ConsumerStatefulWidget {
  const ParentCalendarScreen({super.key});

  @override
  ConsumerState<ParentCalendarScreen> createState() =>
      _ParentCalendarScreenState();
}

class _ParentCalendarScreenState extends ConsumerState<ParentCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final records =
        ref.watch(childMonthRecordsProvider(monthKey(_focused))).value ??
            const [];
    final byDate = {for (final r in records) r.date: r};
    final selectedRec = byDate[dateKey(_selected)];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('출결 달력', style: AppText.screenTitle),
              const SizedBox(height: AppSpace.md),
              _calendar(byDate),
              const SizedBox(height: AppSpace.lg),
              _DetailCard(
                selected: _selected,
                record: selectedRec,
                monthRecords: records,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendar(Map<String, AttendanceRecord> byDate) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: AppDecoration.card(),
      child: TableCalendar<AttendanceRecord>(
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(DateTime.now().year + 1, 12, 31),
        focusedDay: _focused,
        selectedDayPredicate: (d) => isSameDay(d, _selected),
        onDaySelected: (selected, focused) => setState(() {
          _selected = selected;
          _focused = focused;
        }),
        onPageChanged: (focused) => setState(() => _focused = focused),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextFormatter: (date, _) => '${date.year}년 ${date.month}월',
          titleTextStyle: AppText.cardTitle,
        ),
        calendarBuilders: CalendarBuilders<AttendanceRecord>(
          dowBuilder: (context, day) => koreanDow(day),
          defaultBuilder: (context, day, _) =>
              attendanceCell(day, attended: byDate.containsKey(dateKey(day))),
          todayBuilder: (context, day, _) => attendanceCell(day,
              attended: byDate.containsKey(dateKey(day)), isToday: true),
          selectedBuilder: (context, day, _) => attendanceCell(day,
              attended: byDate.containsKey(dateKey(day)), isSelected: true),
        ),
      ),
    );
  }
}

/// 선택 날짜 상세 카드.
class _DetailCard extends StatelessWidget {
  final DateTime selected;
  final AttendanceRecord? record;
  final List<AttendanceRecord> monthRecords;

  const _DetailCard({
    required this.selected,
    required this.record,
    required this.monthRecords,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = '${selected.month}월 ${selected.day}일';
    final r = record;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateText, style: AppText.cardTitle),
          const SizedBox(height: AppSpace.sm),
          if (r == null || !r.isCheckedIn)
            const Text('이 날은 등원 기록이 없어요.', style: AppText.caption)
          else ...[
            _timeline(r),
            if (r.stayDuration != null) ...[
              const SizedBox(height: AppSpace.sm),
              _chip('총 ${formatDuration(r.stayDuration!)} 체류'),
            ],
            ..._summary(r),
          ],
        ],
      ),
    );
  }

  Widget _timeline(AttendanceRecord r) {
    return Row(
      children: [
        _point('등원', formatKoreanTime(r.checkInAt!)),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            color: AppColors.primarySoft,
          ),
        ),
        _point('하원', r.checkOutAt != null
            ? formatKoreanTime(r.checkOutAt!)
            : '수업 중'),
      ],
    );
  }

  Widget _point(String label, String time) {
    return Column(
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 2),
        Text(time,
            style: AppText.cardTitle.copyWith(color: AppColors.primaryDeep)),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text,
          style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
    );
  }

  /// "평소보다 N분 늦게/일찍 하원" — 이번 달 평균 하원 시각과 비교.
  List<Widget> _summary(AttendanceRecord r) {
    if (r.checkOutAt == null) return const [];
    final others = monthRecords
        .where((e) => e.checkOutAt != null && e.date != r.date)
        .map((e) => e.checkOutAt!.toLocal())
        .map((t) => t.hour * 60 + t.minute)
        .toList();
    if (others.length < 2) return const [];

    final avg = others.reduce((a, b) => a + b) ~/ others.length;
    final mine = r.checkOutAt!.toLocal().hour * 60 + r.checkOutAt!.toLocal().minute;
    final diff = mine - avg;
    if (diff.abs() < 5) return const [];

    final word = diff > 0 ? '늦게' : '일찍';
    return [
      const SizedBox(height: AppSpace.sm),
      Text('평소보다 ${diff.abs()}분 $word 하원했어요.', style: AppText.caption),
    ];
  }
}
