import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/firebase/firebase_providers.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/schedule/data/schedule_repository.dart';
import 'package:jigeum_yeogi/models/student.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(firestoreProvider));
});

/// 특정 요일 코드에 등원 예정인 학생 목록. 등원 시각 → 이름 순 정렬.
List<Student> _scheduledOn(List<Student> students, String weekdayCode) {
  return students.where((s) => s.scheduledDays.contains(weekdayCode)).toList()
    ..sort((a, b) {
      final t = (a.timeOn(weekdayCode) ?? '').compareTo(b.timeOn(weekdayCode) ?? '');
      return t != 0 ? t : a.name.compareTo(b.name);
    });
}

/// 오늘 등원 예정 학생.
final todayScheduledStudentsProvider = Provider<List<Student>>((ref) {
  final students = ref.watch(teacherStudentsProvider).value ?? const [];
  return _scheduledOn(students, weekdayCodeOf(DateTime.now()));
});

/// 임의 요일(달력에서 선택한 날짜의 요일)에 등원 예정 학생.
final scheduledOnProvider =
    Provider.family<List<Student>, String>((ref, weekdayCode) {
  final students = ref.watch(teacherStudentsProvider).value ?? const [];
  return _scheduledOn(students, weekdayCode);
});
