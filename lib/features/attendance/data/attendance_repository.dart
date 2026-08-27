import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/student.dart';

/// 출석 데이터 처리.
/// - 선생님: 자기 코드 소속 학생 목록 + 오늘 출석 기록 스트림, 등하원 체크
/// - 학부모: 내 아이 + 특정 날짜/주간 출석 기록
class AttendanceRepository {
  AttendanceRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get _students =>
      _db.collection('students');

  String _docId(String studentId, String date) => '${studentId}_$date';

  // ── 선생님 ─────────────────────────────────────────────
  Stream<List<Student>> teacherStudents(String teacherCode) {
    return _students
        .where('teacherCode', isEqualTo: teacherCode)
        .snapshots()
        .map((s) => s.docs.map(Student.fromDoc).toList());
  }

  Stream<List<AttendanceRecord>> teacherDayRecords(
      String teacherCode, String date) {
    return _attendance
        .where('teacherCode', isEqualTo: teacherCode)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }

  /// 등원 체크 — 등원 시각 기록(문서 없으면 생성).
  Future<void> checkIn(Student student, String date) {
    return _attendance.doc(_docId(student.id, date)).set({
      'studentId': student.id,
      'teacherCode': student.teacherCode,
      'parentUid': student.parentUid,
      'date': date,
      'checkInAt': FieldValue.serverTimestamp(),
      'status': 'present',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 하원 체크 — 하원 시각 기록.
  Future<void> checkOut(Student student, String date) {
    return _attendance.doc(_docId(student.id, date)).set({
      'checkOutAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 출석 기록 초기화 — 등원/하원 시각을 비우고 등원 전(pending)으로.
  /// (보안 규칙상 문서 삭제 금지라 필드를 비우는 방식.)
  Future<void> resetRecord(String studentId, String date) {
    return _attendance.doc(_docId(studentId, date)).set({
      'checkInAt': null,
      'checkOutAt': null,
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 선생님 반의 임의 구간(달력 월 등) 출석 기록.
  Stream<List<AttendanceRecord>> teacherRecordsBetween(
      String teacherCode, String startDate, String endDate) {
    return _attendance
        .where('teacherCode', isEqualTo: teacherCode)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }

  // ── 학부모 ─────────────────────────────────────────────
  Stream<Student?> childOf(String parentUid) {
    return _students
        .where('parentUid', isEqualTo: parentUid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Student.fromDoc(s.docs.first));
  }

  Stream<AttendanceRecord?> studentDayRecord(String studentId, String date) {
    return _attendance.doc(_docId(studentId, date)).snapshots().map(
        (d) => d.exists ? AttendanceRecord.fromDoc(d) : null);
  }

  /// 특정 학부모 자녀의 주간(또는 임의 구간) 출석 기록.
  Stream<List<AttendanceRecord>> childRecordsBetween(
      String parentUid, String startDate, String endDate) {
    return _attendance
        .where('parentUid', isEqualTo: parentUid)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }
}
