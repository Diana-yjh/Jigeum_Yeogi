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
              AttendanceHeader(dateLabel: dateLabel, title: '오늘 출석'),
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

    // 학생 + 오늘 기록 → 표시 상태.
    final rows = students.map((s) {
      final rec = byId[s.id];
      final state = _stateOf(rec);
      return (student: s, state: state, record: rec);
    }).toList();

    final presentCount = rows.where((r) => _isPresent(r.state)).length;
    final visible = rows.where((r) => _matches(r.state)).toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceFilter(
            selected: _type,
            allCount: rows.length,
            presentCount: presentCount,
            absentCount: rows.length - presentCount,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: AppSpace.lg),
          Expanded(
            child: ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (_, i) {
                final row = visible[i];
                return StudentCard(
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
