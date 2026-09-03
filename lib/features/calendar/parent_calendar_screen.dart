import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/features/calendar/widgets/calendar_cells.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/shared/widgets/app_background.dart';
import 'package:jigeum_yeogi/shared/widgets/status_pill.dart';

// 체류 타임바 축(분): 10:00 ~ 20:00.
const _axisStart = 10 * 60;
const _axisEnd = 20 * 60;

/// 학부모 출결 달력 — 커스텀 그리드 + 선택 날짜 체류 상세.
///
/// 자녀가 여러 명이면 한 달력에 모두 표시한다. 아이마다 색을 배정해
/// 날짜 아래 도트를 아이 수만큼 찍고, 상세 카드에 아이별로 한 블록씩 보여준다.
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
    final children = ref.watch(childrenProvider).value ?? const <Student>[];
    final records =
        ref.watch(childMonthRecordsProvider(monthKey(_month))).value ??
            const <AttendanceRecord>[];

    // 같은 이름의 수강은 한 아이로 묶어 같은 색을 쓴다.
    final groupNames = <String>[];
    final groupOf = <String, int>{}; // studentId → 그룹 인덱스
    for (final c in children) {
      final name = c.name.trim();
      var gi = groupNames.indexOf(name);
      if (gi < 0) {
        gi = groupNames.length;
        groupNames.add(name);
      }
      groupOf[c.id] = gi;
    }
    final colorOf = <String, Color>{
      for (final c in children) c.id: AppColors.childColor(groupOf[c.id]!),
    };
    final studentOf = {for (final c in children) c.id: c};
    // 다중 수강 상세에서 선생님을 구분하기 위한 닉네임·색.
    final appUser = ref.watch(appUserProvider).value;
    final directory =
        appUser?.teacherDirectory(children.map((c) => c.teacherCode)) ??
            const <String, String>{};

    // 날짜별 등원 기록(아이 순서대로).
    final byDay = <int, List<AttendanceRecord>>{};
    for (final r in records.where((r) => r.isCheckedIn)) {
      byDay.putIfAbsent(int.parse(r.date.split('-')[2]), () => []).add(r);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => _order(children, a.studentId)
          .compareTo(_order(children, b.studentId)));
    }

    final selected = _selected ?? _autoSelect(byDay);
    final multi = groupNames.length >= 2;

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            Text('출결 달력', style: AppText.screenTitle),
            const SizedBox(height: AppSpace.md),
            _monthHeader(),
            const SizedBox(height: AppSpace.md),
            _summary(groupNames, groupOf, studentOf, records),
            const SizedBox(height: AppSpace.md),
            GestureDetector(
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) _changeMonth(1);
                if (v > 200) _changeMonth(-1);
              },
              child: _grid(byDay, selected, colorOf),
            ),
            const SizedBox(height: AppSpace.md),
            _detail(
              selected,
              byDay[selected.day] ?? const [],
              studentOf: studentOf,
              colorOf: colorOf,
              multi: multi,
              directory: directory,
              appUser: appUser,
            ),
          ],
        ),
      ),
    );
  }

  int _order(List<Student> children, String id) {
    final i = children.indexWhere((c) => c.id == id);
    return i < 0 ? children.length : i;
  }

  /// 오늘(이 달일 때) 우선, 없으면 이 달 마지막 출석일, 그것도 없으면 1일.
  DateTime _autoSelect(Map<int, List<AttendanceRecord>> byDay) {
    final now = DateTime.now();
    if (now.year == _month.year && now.month == _month.month) {
      return DateTime(_month.year, _month.month, now.day);
    }
    final days = byDay.keys.toList()..sort();
    final day = days.isNotEmpty ? days.last : 1;
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

  // ── 월간 요약(이번 달 출석) — 다자녀일 땐 색 범례 역할도 겸한다 ──
  // 같은 이름의 수강은 하나로 합산한다.
  Widget _summary(List<String> groupNames, Map<String, int> groupOf,
      Map<String, Student> studentOf, List<AttendanceRecord> records) {
    int countOf(int gi) => records
        .where((r) => groupOf[r.studentId] == gi && r.isCheckedIn)
        .length;
    if (groupNames.length < 2) {
      final count = records.where((r) => r.isCheckedIn).length;
      return _statCard(caption: '이번 달 출석', child: _countText('$count'));
    }
    return _statCard(
      caption: '이번 달 출석',
      child: Wrap(
        spacing: AppSpace.md,
        runSpacing: AppSpace.xs,
        children: [
          for (var gi = 0; gi < groupNames.length; gi++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: AppColors.childColor(gi), size: 8),
                const SizedBox(width: 6),
                Text(groupNames[gi], style: AppText.caption),
                const SizedBox(width: 6),
                _countText('${countOf(gi)}'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _countText(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain)),
        const SizedBox(width: 2),
        Text('회', style: AppText.caption.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _statCard({required String caption, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDecoration.card(radius: AppRadius.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: AppText.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }

  // ── 달력 그리드 ──
  Widget _grid(Map<int, List<AttendanceRecord>> byDay, DateTime selected,
      Map<String, Color> colorOf) {
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
                        selected, now, colorOf),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(
      int day,
      int daysInMonth,
      Map<int, List<AttendanceRecord>> byDay,
      DateTime selected,
      DateTime now,
      Map<String, Color> colorOf) {
    // 앞뒤 달 날짜.
    if (day < 1 || day > daysInMonth) {
      final outDate = DateTime(_month.year, _month.month, day);
      return _CellButton(
        onTap: () => setState(() {
          _month = DateTime(outDate.year, outDate.month, 1);
          _selected = outDate;
        }),
        child: _cellBody('${outDate.day}',
            numberColor: AppColors.textFaint, dots: const []),
      );
    }

    // 같은 아이(그룹)가 같은 날 여러 수강 등원해도 도트는 하나.
    final seen = <int>{};
    final dots = <Color>[];
    for (final r in byDay[day] ?? const <AttendanceRecord>[]) {
      final c = colorOf[r.studentId] ?? AppColors.primary;
      if (seen.add(c.toARGB32())) dots.add(c);
    }
    final isSelected = selected.day == day;
    final isToday = now.year == _month.year &&
        now.month == _month.month &&
        now.day == day;

    final Widget body = isSelected
        ? _cellBody('$day',
            numberColor: Colors.white, selectedCircle: true, dots: dots)
        : _cellBody('$day',
            numberColor: isToday ? AppColors.primary : AppColors.textMain,
            dots: dots);

    return _CellButton(
      onTap: () =>
          setState(() => _selected = DateTime(_month.year, _month.month, day)),
      child: body,
    );
  }

  /// 날짜 숫자 + 아래 도트들. 도트는 아이 색 순서대로 최대 4개.
  Widget _cellBody(String number,
      {required Color numberColor,
      bool selectedCircle = false,
      required List<Color> dots}) {
    final shown = dots.take(4).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarDayNumber(
            number: number,
            decoration: selectedCircle
                ? const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)
                : null,
            style: TextStyle(
                fontSize: 14,
                color: numberColor,
                fontWeight: selectedCircle ? FontWeight.w600 : FontWeight.w400),
          ),
          const SizedBox(height: 6),
          // 도트가 없어도 높이는 유지(행 높이 흔들림 방지).
          SizedBox(
            height: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  _Dot(color: shown[i], size: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 선택 날짜 상세 ──
  Widget _detail(
    DateTime date,
    List<AttendanceRecord> recs, {
    required Map<String, Student> studentOf,
    required Map<String, Color> colorOf,
    required bool multi,
    required Map<String, String> directory,
    required AppUser? appUser,
  }) {
    final dateText = '${date.month}월 ${date.day}일 ${weekdayLabelOf(date)}요일';
    const dateStyle = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain);
    final dayCode = weekdayCodes[date.weekday - 1];

    if (recs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: AppDecoration.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText, style: dateStyle),
            const SizedBox(height: AppSpace.sm),
            const Text('이 날은 기록이 없어요',
                style: TextStyle(fontSize: 14, color: AppColors.textSub)),
          ],
        ),
      );
    }

    // 자녀 한 명·단일 기록: 날짜 옆에 정규/보충 pill, 아래 타임바.
    // (한 아이 다중 수강으로 같은 날 기록이 2개면 아래 블록형으로 내려간다)
    if (!multi && recs.length == 1) {
      final r = recs.first;
      final isMakeup =
          studentOf[r.studentId]?.typeOn(dayCode) == ClassType.makeup;
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
                Text(dateText, style: dateStyle),
                isMakeup
                    ? const StatusPill.makeup()
                    : const StatusPill.regular(),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            _StayRow(record: r, color: AppColors.primaryDeep),
            const SizedBox(height: AppSpace.sm),
            _AxisCaption(record: r),
          ],
        ),
      );
    }

    // 자녀 여러 명: 날짜 아래 아이별 블록(색 도트 + 이름 + pill / 타임바 / 체류).
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateText, style: dateStyle),
          const SizedBox(height: AppSpace.md),
          for (var i = 0; i < recs.length; i++) ...[
            if (i > 0)
              const Divider(height: AppSpace.lg, color: AppColors.cardBorder),
            _ChildStayBlock(
              record: recs[i],
              student: studentOf[recs[i].studentId],
              color: colorOf[recs[i].studentId] ?? AppColors.primary,
              dayCode: dayCode,
              teacherLabel: directory.length >= 2
                  ? directory[recs[i].teacherCode]
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// 다자녀 상세 — 아이 한 명 분량: 이름 행 + 타임바 + 체류 시간.
class _ChildStayBlock extends StatelessWidget {
  final AttendanceRecord record;
  final Student? student;
  final Color color;
  final String dayCode;
  final String? teacherLabel; // 다중 선생님일 때 어느 반 기록인지
  const _ChildStayBlock({
    required this.record,
    required this.student,
    required this.color,
    required this.dayCode,
    this.teacherLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isMakeup = student?.typeOn(dayCode) == ClassType.makeup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Dot(color: color, size: 8),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(student?.name ?? '우리 아이',
                  style: AppText.cardTitle, overflow: TextOverflow.ellipsis),
            ),
            if (teacherLabel != null) ...[
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: Text(teacherLabel!,
                    style: AppText.caption, overflow: TextOverflow.ellipsis),
              ),
            ],
            const Spacer(),
            isMakeup ? const StatusPill.makeup() : const StatusPill.regular(),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        _StayRow(record: record, color: color),
        const SizedBox(height: AppSpace.xs),
        _AxisCaption(record: record),
      ],
    );
  }
}

/// 등원 시각 ── 체류 막대 ── 하원 시각.
class _StayRow extends StatelessWidget {
  final AttendanceRecord record;
  final Color color;
  const _StayRow({required this.record, required this.color});

  @override
  Widget build(BuildContext context) {
    final inAt = record.checkInAt!;
    final outAt = record.checkOutAt;
    final style =
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color);
    return Row(
      children: [
        Text(clock(inAt), style: style),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _StayBar(
              inAt: inAt, endAt: outAt ?? DateTime.now(), color: color),
        ),
        const SizedBox(width: AppSpace.sm),
        Text(outAt != null ? clock(outAt) : '--:--', style: style),
      ],
    );
  }
}

/// 축 라벨(10시 / N시간 체류 / 20시).
class _AxisCaption extends StatelessWidget {
  final AttendanceRecord record;
  const _AxisCaption({required this.record});

  @override
  Widget build(BuildContext context) {
    final end = record.checkOutAt ?? DateTime.now();
    final stay = end.difference(record.checkInAt!);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${_axisStart ~/ 60}시', style: AppText.caption),
        Text('${formatDuration(stay)} 체류', style: AppText.caption),
        Text('${_axisEnd ~/ 60}시', style: AppText.caption),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

/// 체류 구간 막대(10~20시 축). 막대 색은 아이 색을 옅게 쓴다.
class _StayBar extends StatelessWidget {
  final DateTime inAt;
  final DateTime endAt;
  final Color color;
  const _StayBar(
      {required this.inAt, required this.endAt, required this.color});

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
                    color: color.withValues(alpha: 0.35),
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
