import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/models/attendance_types.dart';
import 'package:jigeum_yeogi/features/attendance/models/attendance_student.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/attendance/widgets/attendance_filter.dart';
import 'package:jigeum_yeogi/features/attendance/widgets/attendance_header.dart';
import 'package:jigeum_yeogi/features/attendance/widgets/student_card.dart';
import 'package:jigeum_yeogi/features/calendar/teacher_calendar_screen.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/student.dart';

/// 출석 화면 (선생님). 실 데이터: 내 코드 소속 학생 + 오늘 출석 기록.
/// 학생별 버튼 한 번으로 등원 → 하원 체크.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  AttendanceTypes _type = AttendanceTypes.all;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  CheckState _stateOf(AttendanceRecord? r) {
    if (r == null) return CheckState.pending;
    if (r.isCheckedOut) return CheckState.checkedOut;
    if (r.isCheckedIn) return CheckState.checkedIn;
    if (r.status == AttendanceStatus.expectedAbsent) {
      return CheckState.expectedAbsent;
    }
    return CheckState.pending;
  }

  bool _isPresent(CheckState s) =>
      s == CheckState.checkedIn || s == CheckState.checkedOut;

  bool _matches(CheckState s) {
    switch (_type) {
      case AttendanceTypes.all:
        return true;
      case AttendanceTypes.present:
        return _isPresent(s);
      case AttendanceTypes.absent:
        return !_isPresent(s);
    }
  }

  Future<void> _onTap(Student student, CheckState state) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final today = ref.read(todayKeyProvider);
    try {
      if (state == CheckState.pending) {
        await repo.checkIn(student, today);
      } else if (state == CheckState.checkedIn) {
        // 하원은 한 번 더 확인.
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('하원 확인'),
            content: Text('${student.name} 학생을 하원 처리할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDeep),
                child: const Text('하원'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        await repo.checkOut(student, today);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 중 문제가 발생했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final recordsAsync = ref.watch(teacherTodayRecordsProvider);

    final now = DateTime.now();
    final dateLabel = '${now.month}월 ${now.day}일 ${_weekdays[now.weekday - 1]}요일';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AttendanceHeader(
                        dateLabel: dateLabel, title: '오늘 출석'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined,
                        color: AppColors.primaryDeep),
                    tooltip: '출결 달력',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TeacherCalendarScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              studentsAsync.when(
                loading: () => const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))),
                error: (_, _) => const Expanded(
                    child: Center(child: Text('학생을 불러오지 못했어요.'))),
                data: (students) {
                  final records = recordsAsync.value ?? const [];
                  final byId = {for (final r in records) r.studentId: r};
                  return _buildList(students, byId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
      List<Student> students, Map<String, AttendanceRecord> byId) {
    if (students.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            '아직 등록된 학생이 없어요.\n학부모가 코드로 가입하면 여기에 표시됩니다.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ),
      );
    }

    final todayCode = weekdayCodeOf(DateTime.now());

    // 학생 + 오늘 기록 → 표시 상태.
    final rows = students.map((s) {
      final rec = byId[s.id];
      final state = _stateOf(rec);
      final scheduled = s.schedule.containsKey(todayCode);
      return (student: s, state: state, record: rec, scheduled: scheduled);
    }).toList();

    // 오늘 예정이거나 오늘 활동(등원/하원/결석예정)이 있으면 정규 목록,
    // 예정도 활동도 없으면 회색 처리.
    final todayRows =
        rows.where((r) => r.scheduled || r.state != CheckState.pending).toList();
    final otherRows =
        rows.where((r) => !r.scheduled && r.state == CheckState.pending).toList();

    final presentCount = todayRows.where((r) => _isPresent(r.state)).length;
    final visibleToday = todayRows.where((r) => _matches(r.state)).toList()
      ..sort((a, b) => _timeKey(a, todayCode).compareTo(_timeKey(b, todayCode)));

    // 리스트 아이템: 1시간 단위 시간대 그룹 헤더 + 학생 카드.
    final items = <Widget>[];
    int? curHour;
    var started = false;
    for (final row in visibleToday) {
      final h = _hourOf(row, todayCode);
      if (!started || h != curHour) {
        started = true;
        curHour = h;
        final count = visibleToday.where((r) => _hourOf(r, todayCode) == h).length;
        items.add(_groupHeader(_hourLabel(h), count));
      }
      items.add(_card(row, dimmed: false));
    }
    final showOthers = _type == AttendanceTypes.all && otherRows.isNotEmpty;
    if (showOthers) {
      items.add(const Padding(
        padding: EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.xs),
        child: Text('오늘 예정 아님', style: AppText.caption),
      ));
      for (final row in otherRows) {
        items.add(_card(row, dimmed: true));
      }
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceFilter(
            selected: _type,
            allCount: todayRows.length,
            presentCount: presentCount,
            absentCount: todayRows.length - presentCount,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: AppSpace.lg),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('오늘 출석한 학생이 아직 없어요.',
                        style: AppText.caption))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.sm),
                    itemBuilder: (_, i) => items[i],
                  ),
          ),
        ],
      ),
    );
  }

  /// 오늘 요일 등원 예정 시각의 '시'(없으면 null → 시간 미정).
  int? _hourOf(
      ({Student student, CheckState state, AttendanceRecord? record, bool scheduled})
          row,
      String todayCode) {
    final t = row.student.timeOn(todayCode);
    if (t == null || t.isEmpty) return null;
    return int.tryParse(t.split(':').first);
  }

  /// 정렬 키(시간 없으면 맨 뒤).
  String _timeKey(
      ({Student student, CheckState state, AttendanceRecord? record, bool scheduled})
          row,
      String todayCode) {
    final t = row.student.timeOn(todayCode);
    return (t == null || t.isEmpty) ? '99:99' : t;
  }

  /// 1시간 단위 그룹 라벨. 예: "오후 3시".
  String _hourLabel(int? hour) {
    if (hour == null) return '시간 미정';
    final ampm = hour < 12 ? '오전' : '오후';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$ampm $h12시';
  }

  Widget _groupHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.xs),
      child: Row(
        children: [
          Text(label,
              style: AppText.caption.copyWith(
                  color: AppColors.primaryDeep, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpace.sm),
          Text('$count명', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _card(
    ({Student student, CheckState state, AttendanceRecord? record, bool scheduled})
        row, {
    required bool dimmed,
  }) {
    return StudentCard(
      dimmed: dimmed,
      student: AttendanceStudent(
        name: row.student.name,
        state: row.state,
        checkInAt: row.record?.checkInAt != null
            ? formatKoreanTime(row.record!.checkInAt!)
            : null,
        checkOutAt: row.record?.checkOutAt != null
            ? formatKoreanTime(row.record!.checkOutAt!)
            : null,
      ),
      onTapAction: () => _onTap(row.student, row.state),
    );
  }
}
