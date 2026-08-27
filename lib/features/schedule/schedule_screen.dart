import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/calendar/widgets/calendar_cells.dart';
import 'package:jigeum_yeogi/features/schedule/state/schedule_providers.dart';
import 'package:jigeum_yeogi/features/schedule/student_schedule_screen.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';

/// 선생님 스케줄 화면 — 학생별 설정(탭 → 상세) + 월간 보기.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _mode = 0; // 0: 학생별 설정, 1: 월간 보기

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final todayScheduled = ref.watch(todayScheduledStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('스케줄', style: AppText.screenTitle),
              const SizedBox(height: AppSpace.md),
              _TodaySummary(count: todayScheduled.length),
              const SizedBox(height: AppSpace.md),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('학생별 설정')),
                  ButtonSegment(value: 1, label: Text('월간 보기')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? AppColors.primary
                          : AppColors.card),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? Colors.white
                          : AppColors.textSub),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Expanded(
                child: studentsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                  error: (_, _) =>
                      const Center(child: Text('학생을 불러오지 못했어요.')),
                  data: (students) {
                    if (students.isEmpty) {
                      return const Center(
                        child: Text(
                          '아직 등록된 학생이 없어요.\n학부모가 코드로 가입하면 여기에 표시됩니다.',
                          textAlign: TextAlign.center,
                          style: AppText.caption,
                        ),
                      );
                    }
                    return _mode == 0
                        ? _StudentList(students: students)
                        : _MonthlyView(students: students);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘 등원 예정 요약.
class _TodaySummary extends StatelessWidget {
  final int count;
  const _TodaySummary({required this.count});

  @override
  Widget build(BuildContext context) {
    final today = weekdayLabelOf(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text('오늘($today) 등원 예정 $count명',
                style:
                    AppText.cardTitle.copyWith(color: AppColors.primaryDeep)),
          ),
        ],
      ),
    );
  }
}

/// 학생 목록 — 탭하면 학생 스케줄 상세로 이동.
class _StudentList extends StatelessWidget {
  final List<Student> students;
  const _StudentList({required this.students});

  String _summary(Student s) {
    if (s.schedule.isEmpty) return '스케줄 미설정';
    final parts = [
      for (var d = 0; d < 7; d++)
        if (s.schedule.containsKey(weekdayCodes[d])) weekdayLabels[d]
    ];
    return parts.join('·');
  }

  bool _hasMakeup(Student s) =>
      s.schedule.values.any((e) => e.type == ClassType.makeup);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (_, i) {
        final s = students[i];
        return Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => StudentScheduleScreen(student: s)),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border:
                    Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(s.name.characters.first,
                        style: AppText.cardTitle
                            .copyWith(color: AppColors.primaryDeep)),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.name, style: AppText.cardTitle),
                            if (_hasMakeup(s)) ...[
                              const SizedBox(width: AppSpace.sm),
                              _makeupTag(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_summary(s), style: AppText.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textFaint),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _makeupTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.chipNeutral,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('보충 포함',
          style: AppText.caption.copyWith(color: AppColors.textSub)),
    );
  }
}

/// 월간 보기 — 날짜 선택 시 그 요일 등원 예정 명단(시간·유형).
class _MonthlyView extends ConsumerStatefulWidget {
  final List<Student> students;
  const _MonthlyView({required this.students});

  @override
  ConsumerState<_MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends ConsumerState<_MonthlyView> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  int _countOn(DateTime day) {
    final code = weekdayCodeOf(day);
    return widget.students.where((s) => s.schedule.containsKey(code)).length;
  }

  @override
  Widget build(BuildContext context) {
    final code = weekdayCodeOf(_selected);
    final selectedList = ref.watch(scheduledOnProvider(code));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
            ),
            child: TableCalendar<Object>(
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
                titleTextFormatter: (date, _) =>
                    '${date.year}년 ${date.month}월',
                titleTextStyle: AppText.cardTitle,
              ),
              calendarBuilders: CalendarBuilders<Object>(
                dowBuilder: (context, day) => koreanDow(day),
                defaultBuilder: (context, day, _) =>
                    attendanceCell(day, attended: _countOn(day) > 0),
                todayBuilder: (context, day, _) => attendanceCell(day,
                    attended: _countOn(day) > 0, isToday: true),
                selectedBuilder: (context, day, _) => attendanceCell(day,
                    attended: _countOn(day) > 0, isSelected: true),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            '${_selected.month}월 ${_selected.day}일(${weekdayLabelOf(_selected)}) 등원 예정 ${selectedList.length}명',
            style: AppText.cardTitle,
          ),
          const SizedBox(height: AppSpace.sm),
          if (selectedList.isEmpty)
            const Text('이 날 등원 예정인 학생이 없어요.', style: AppText.caption)
          else
            ...selectedList.map((s) => _row(s, code)),
        ],
      ),
    );
  }

  Widget _row(Student s, String code) {
    final time = s.timeOn(code);
    final isMakeup = s.typeOn(code) == ClassType.makeup;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primarySoft,
            child: Text(s.name.characters.first,
                style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(s.name, style: AppText.body)),
          if (isMakeup) ...[
            Text('보충 ',
                style: AppText.caption.copyWith(color: AppColors.textSub)),
          ],
          Text(
            (time != null && time.isNotEmpty) ? formatHhmm(time) : '시간 미정',
            style: AppText.caption.copyWith(color: AppColors.primaryDeep),
          ),
        ],
      ),
    );
  }
}
