import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/firebase/firebase_providers.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/data/attendance_repository.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/student.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(firestoreProvider));
});

/// 오늘 날짜 키(yyyy-MM-dd).
final todayKeyProvider = Provider<String>((ref) => dateKey(DateTime.now()));

// ── 선생님 ───────────────────────────────────────────────
/// 내 코드 소속 학생 목록.
final teacherStudentsProvider = StreamProvider<List<Student>>((ref) {
  final code = ref.watch(appUserProvider).value?.teacherCode;
  if (code == null) return Stream.value(const []);
  return ref.watch(attendanceRepositoryProvider).teacherStudents(code);
});

/// 오늘 반 전체 출석 기록.
final teacherTodayRecordsProvider =
    StreamProvider<List<AttendanceRecord>>((ref) {
  final code = ref.watch(appUserProvider).value?.teacherCode;
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayKeyProvider);
  return ref
      .watch(attendanceRepositoryProvider)
      .teacherDayRecords(code, today);
});

// ── 학부모 ───────────────────────────────────────────────
/// 내 아이(첫 자녀).
final childProvider = StreamProvider<Student?>((ref) {
  final uid = ref.watch(appUserProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(attendanceRepositoryProvider).childOf(uid);
});

/// 내 아이의 오늘 출석 기록.
final childTodayRecordProvider = StreamProvider<AttendanceRecord?>((ref) {
  final child = ref.watch(childProvider).value;
  if (child == null) return Stream.value(null);
  final today = ref.watch(todayKeyProvider);
  return ref
      .watch(attendanceRepositoryProvider)
      .studentDayRecord(child.id, today);
});

/// 내 아이의 이번 주(월~일) 출석 기록.
final childWeekRecordsProvider =
    StreamProvider<List<AttendanceRecord>>((ref) {
  final uid = ref.watch(appUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return ref
      .watch(attendanceRepositoryProvider)
      .childRecordsBetween(uid, dateKey(monday), dateKey(sunday));
});
