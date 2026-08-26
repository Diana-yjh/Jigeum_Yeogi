/// 출석 화면용 학생 표시 모델 (Phase 1: 더미).
/// Phase 3에서 Firestore students + attendance 기록으로 대체 예정.
enum CheckState { pending, checkedIn, checkedOut, expectedAbsent }

class AttendanceStudent {
  final String name;
  final CheckState state;
  final String? checkInAt; // 등원 시각 (HH:mm) — 더미 문자열
  final String? checkOutAt; // 하원 시각 (HH:mm)

  const AttendanceStudent({
    required this.name,
    required this.state,
    this.checkInAt,
    this.checkOutAt,
  });
}
