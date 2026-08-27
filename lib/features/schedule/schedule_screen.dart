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
import 'package:jigeum_yeogi/models/student.dart';

const _defaultSlot = '15:00';

/// 선생님 스케줄 화면 — 매주 반복(요일+시간) 편집 + 월간 보기.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _mode = 0; // 0: 주간 편집, 1: 월간 보기

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
                  ButtonSegment(value: 0, label: Text('주간 편집')),
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
                        ? _WeeklyEditor(students: students)
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

/// 주간 편집 — 학생별 요일 토글 + 요일별 시간(30분 단위).
class _WeeklyEditor extends ConsumerWidget {
  final List<Student> students;
  const _WeeklyEditor({required this.students});

  void _toggleDay(WidgetRef ref, Student s, String code) {
    final next = Map<String, String>.from(s.schedule);
    if (next.containsKey(code)) {
      next.remove(code);
    } else {
      next[code] = _defaultSlot;
    }
    ref.read(scheduleRepositoryProvider).setSchedule(s.id, next);
  }

  void _setTime(WidgetRef ref, Student s, String code, String time) {
    final next = Map<String, String>.from(s.schedule)..[code] = time;
    ref.read(scheduleRepositoryProvider).setSchedule(s.id, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (_, i) {
        final s = students[i];
        // 선택된 요일들(요일 순서대로).
        final onDays = [
          for (var d = 0; d < 7; d++)
            if (s.schedule.containsKey(weekdayCodes[d])) d
        ];
        return Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name, style: AppText.cardTitle),
              const SizedBox(height: AppSpace.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var d = 0; d < 7; d++)
                    _dayToggle(ref, s, d),
                ],
              ),
              if (onDays.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: AppSpace.xs),
                for (final d in onDays) _timeRow(ref, s, d),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dayToggle(WidgetRef ref, Student s, int dayIndex) {
    final code = weekdayCodes[dayIndex];
    final on = s.schedule.containsKey(code);
    return GestureDetector(
      onTap: () => _toggleDay(ref, s, code),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.chipNeutral,
          shape: BoxShape.circle,
        ),
        child: Text(
          weekdayLabels[dayIndex],
          style: AppText.caption.copyWith(
            color: on ? Colors.white : AppColors.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _timeRow(WidgetRef ref, Student s, int dayIndex) {
    final code = weekdayCodes[dayIndex];
    final time = s.schedule[code];
    final value = (time != null && scheduleTimeSlots.contains(time)) ? time : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(weekdayLabels[dayIndex],
                style: AppText.body.copyWith(color: AppColors.primaryDeep)),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('시간 선택', style: AppText.caption),
              items: [
                for (final slot in scheduleTimeSlots)
                  DropdownMenuItem(
                    value: slot,
                    child: Text(formatHhmm(slot), style: AppText.body),
                  ),
              ],
              onChanged: (t) {
                if (t != null) _setTime(ref, s, code, t);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 월간 보기 — 날짜 선택 시 그 요일 등원 예정 명단(시간 포함).
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
            ...selectedList.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primarySoft,
                        child: Text(s.name.characters.first,
                            style: AppText.caption
                                .copyWith(color: AppColors.primaryDeep)),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: Text(s.name, style: AppText.body)),
                      Text(
                        (s.timeOn(code)?.isNotEmpty ?? false)
                            ? formatHhmm(s.timeOn(code)!)
                            : '시간 미정',
                        style: AppText.caption
                            .copyWith(color: AppColors.primaryDeep),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
