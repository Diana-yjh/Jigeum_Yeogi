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
  DateTime _selected = DateTime.now(); // 월간 보기에서 선택한 날짜

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider);
    // 학생별 설정 모드는 오늘, 월간 보기 모드는 선택 날짜 기준으로 요약.
    final summaryDate = _mode == 1 ? _selected : DateTime.now();
    final summaryCount =
        ref.watch(scheduledOnProvider(weekdayCodeOf(summaryDate))).length;

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
              _ScheduleSummary(date: summaryDate, count: summaryCount),
              const SizedBox(height: AppSpace.md),
              _SegmentToggle(
                labels: const ['학생별 설정', '월간 보기'],
                selected: _mode,
                onChanged: (i) => setState(() => _mode = i),
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
                        : _MonthlyView(
                            students: students,
                            selected: _selected,
                            onSelected: (d) => setState(() => _selected = d),
                          );
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

/// 뉴트럴 트랙 위에 흰 pill이 움직이는 세그먼트 토글.
class _SegmentToggle extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SegmentToggle({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chipNeutral,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: i == selected
                        ? const [
                            BoxShadow(
                              color: Color(0x14453121),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: AppText.caption.copyWith(
                      color: i == selected
                          ? AppColors.primaryDeep
                          : AppColors.textSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 등원 예정 요약 — 선택 날짜(또는 오늘) 기준.
class _ScheduleSummary extends StatelessWidget {
  final DateTime date;
  final int count;
  const _ScheduleSummary({required this.date, required this.count});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday
        ? '오늘(${weekdayLabelOf(date)}) 등원 예정 $count명'
        : '${date.month}월 ${date.day}일(${weekdayLabelOf(date)}) 등원 예정 $count명';

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
            child: Text(label,
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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => StudentScheduleScreen(student: s)),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: AppDecoration.card(),
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
/// 선택 날짜는 부모(ScheduleScreen)가 소유해 상단 요약과 공유한다.
class _MonthlyView extends ConsumerStatefulWidget {
  final List<Student> students;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  const _MonthlyView({
    required this.students,
    required this.selected,
    required this.onSelected,
  });

  @override
  ConsumerState<_MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends ConsumerState<_MonthlyView> {
  DateTime _focused = DateTime.now();
  DateTime get _selected => widget.selected;

  int _countOn(DateTime day) {
    final code = weekdayCodeOf(day);
    return widget.students.where((s) => s.schedule.containsKey(code)).length;
  }

  /// 날짜 + 그 날 등원 예정 인원수. 색 원 대신 숫자로 의미를 준다.
  Widget _cell(DateTime day,
      {bool isToday = false, bool isSelected = false, bool outside = false}) {
    final count = outside ? 0 : _countOn(day);
    final numberColor = outside
        ? AppColors.textFaint
        : isSelected
            ? Colors.white
            : (isToday ? AppColors.primaryDeep : AppColors.textMain);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: isSelected
                ? const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)
                : null,
            child: Text('${day.day}',
                style: TextStyle(
                    fontSize: 14,
                    color: numberColor,
                    fontWeight:
                        (isSelected || isToday) ? FontWeight.w700 : FontWeight.w400)),
          ),
          const SizedBox(height: 3),
          Text(
            count > 0 ? '$count' : '',
            style: AppText.caption.copyWith(
                fontSize: 11,
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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
            decoration: AppDecoration.card(),
            child: TableCalendar<Object>(
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(DateTime.now().year + 1, 12, 31),
              focusedDay: _focused,
              rowHeight: 64, // 날짜+인원수 두 줄 여유(글씨 확대 대응)
              daysOfWeekHeight: 24,
              // 세로 스와이프는 페이지 스크롤에 양보(가로만 월 이동).
              availableGestures: AvailableGestures.horizontalSwipe,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              onDaySelected: (selected, focused) {
                setState(() => _focused = focused);
                widget.onSelected(selected); // 부모로 선택 날짜 전달
              },
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
                defaultBuilder: (context, day, _) => _cell(day),
                todayBuilder: (context, day, _) => _cell(day, isToday: true),
                selectedBuilder: (context, day, _) =>
                    _cell(day, isSelected: true),
                outsideBuilder: (context, day, _) => _cell(day, outside: true),
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
