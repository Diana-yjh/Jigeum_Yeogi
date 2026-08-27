import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `status` 필드 값.
enum AttendanceStatus { pending, present, absent, expectedAbsent }

AttendanceStatus _statusFrom(String? s) {
  switch (s) {
    case 'present':
      return AttendanceStatus.present;
    case 'absent':
      return AttendanceStatus.absent;
    case 'expected_absent':
      return AttendanceStatus.expectedAbsent;
    default:
      return AttendanceStatus.pending;
  }
}

/// 최상위 `attendance/{studentId}_{date}` 문서와 매핑되는 출석 기록.
///
/// 스펙의 중첩(`attendance/{sid}/records/{date}`) 대신 최상위 컬렉션으로 두고
/// teacherCode·parentUid·date를 비정규화해 반 전체/주간 조회를 단순화했다.
class AttendanceRecord {
  final String studentId;
  final String date; // yyyy-MM-dd
  final String teacherCode;
  final String? parentUid;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.studentId,
    required this.date,
    required this.teacherCode,
    this.parentUid,
    this.checkInAt,
    this.checkOutAt,
    this.status = AttendanceStatus.pending,
  });

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return AttendanceRecord(
      studentId: (m['studentId'] as String?) ?? '',
      date: (m['date'] as String?) ?? '',
      teacherCode: (m['teacherCode'] as String?) ?? '',
      parentUid: m['parentUid'] as String?,
      checkInAt: (m['checkInAt'] as Timestamp?)?.toDate(),
      checkOutAt: (m['checkOutAt'] as Timestamp?)?.toDate(),
      status: _statusFrom(m['status'] as String?),
    );
  }

  bool get isCheckedIn => checkInAt != null;
  bool get isCheckedOut => checkOutAt != null;

  /// 등원~하원 총 체류 시간.
  Duration? get stayDuration =>
      (checkInAt != null && checkOutAt != null)
          ? checkOutAt!.difference(checkInAt!)
          : null;
}
