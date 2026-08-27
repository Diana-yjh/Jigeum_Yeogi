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

/// 선생님 출결 달력 — 날짜별 출석한 아이 명단·시각.
/// (출석 화면 상단 달력 아이콘으로 진입)
class TeacherCalendarScreen extends ConsumerStatefulWidget {
  const TeacherCalendarScreen({super.key});

  @override
  ConsumerState<TeacherCalendarScreen> createState() =>
      _TeacherCalendarScreenState();
}

class _TeacherCalendarScreenState extends ConsumerState<TeacherCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final records =
        ref.watch(teacherMonthRecordsProvider(monthKey(_focused))).value ??
            const [];
    final students = ref.watch(teacherStudentsProvider).value ?? const [];
    final nameById = {for (final s in students) s.id: s.name};

    // 날짜별 등원 인원.
    final attendedDates = <String>{
      for (final r in records)
        if (r.isCheckedIn) r.date,
    };
    final dayRecords = records
        .where((r) => r.date == dateKey(_selected) && r.isCheckedIn)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textMain,
        title: const Text('출결 달력'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _calendar(attendedDates),
              const SizedBox(height: AppSpace.lg),
              Text('${_selected.month}월 ${_selected.day}일 · 등원 ${dayRecords.length}명',
                  style: AppText.cardTitle),
              const SizedBox(height: AppSpace.sm),
              if (dayRecords.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: Text('이 날 등원한 학생이 없어요.', style: AppText.caption),
                )
              else
                ...dayRecords.map((r) => _studentRow(
                    nameById[r.studentId] ?? '학생', r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendar(Set<String> attendedDates) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: AppDecoration.card(),
      child: TableCalendar<AttendanceRecord>(
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(DateTime.now().year + 1, 12, 31),
        focusedDay: _focused,
        rowHeight: 56, // 글씨 확대 대응(오버플로 방지)
        daysOfWeekHeight: 24,
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
              attendanceCell(day, attended: attendedDates.contains(dateKey(day))),
          todayBuilder: (context, day, _) => attendanceCell(day,
              attended: attendedDates.contains(dateKey(day)), isToday: true),
          selectedBuilder: (context, day, _) => attendanceCell(day,
              attended: attendedDates.contains(dateKey(day)), isSelected: true),
        ),
      ),
    );
  }

  Widget _studentRow(String name, AttendanceRecord r) {
    final times = r.checkOutAt != null
        ? '${formatKoreanTime(r.checkInAt!)} → ${formatKoreanTime(r.checkOutAt!)}'
        : '${formatKoreanTime(r.checkInAt!)} 등원';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySoft,
            child: Text(name.characters.first,
                style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(name, style: AppText.body)),
          Text(times, style: AppText.caption),
        ],
      ),
    );
  }
}
