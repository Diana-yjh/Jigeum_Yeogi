import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/features/attendance/models/attendance_types.dart';
import 'package:jigeum_yeogi/features/attendance/models/attendance_student.dart';
import 'package:jigeum_yeogi/features/attendance/widgets/attendance_filter.dart';
import 'package:jigeum_yeogi/features/attendance/widgets/attendance_header.dart';
import 'package:jigeum_yeogi/features/attendance/widgets/student_card.dart';

/// 출석 화면 (선생님). Phase 1: 더미 학생 리스트 + 필터.
/// Phase 3에서 실제 등원/하원 체크 및 attendance 기록으로 연결 예정.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceTypes _type = AttendanceTypes.all;

  // 더미 학생 데이터.
  static const _students = <AttendanceStudent>[
    AttendanceStudent(name: '김서준', state: CheckState.checkedIn, checkInAt: '15:02'),
    AttendanceStudent(name: '이하은', state: CheckState.checkedIn, checkInAt: '15:05'),
    AttendanceStudent(
        name: '박도윤',
        state: CheckState.checkedOut,
        checkInAt: '14:58',
        checkOutAt: '17:30'),
    AttendanceStudent(name: '최지우', state: CheckState.pending),
    AttendanceStudent(name: '정시아', state: CheckState.pending),
    AttendanceStudent(name: '강민준', state: CheckState.expectedAbsent),
  ];

  bool _matches(AttendanceStudent s) {
    switch (_type) {
      case AttendanceTypes.all:
        return true;
      case AttendanceTypes.present:
        return s.state == CheckState.checkedIn ||
            s.state == CheckState.checkedOut;
      case AttendanceTypes.absent:
        return s.state == CheckState.pending ||
            s.state == CheckState.expectedAbsent;
    }
  }

  int get _presentCount => _students
      .where((s) =>
          s.state == CheckState.checkedIn || s.state == CheckState.checkedOut)
      .length;

  @override
  Widget build(BuildContext context) {
    final visible = _students.where(_matches).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AttendanceHeader(
                dateLabel: '8월 26일 수요일',
                title: '초등 A반 출석',
              ),
              const SizedBox(height: AppSpace.lg),
              AttendanceFilter(
                selected: _type,
                allCount: _students.length,
                presentCount: _presentCount,
                absentCount: _students.length - _presentCount,
                onChanged: (type) => setState(() => _type = type),
              ),
              const SizedBox(height: AppSpace.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.sm),
                  itemBuilder: (_, i) => StudentCard(student: visible[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
