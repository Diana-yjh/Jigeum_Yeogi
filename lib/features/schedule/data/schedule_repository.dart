import 'package:cloud_firestore/cloud_firestore.dart';

/// 학생 스케줄(매주 반복, 요일별 시간) 처리.
/// schedule: { 'mon': '15:00', 'wed': '16:30' } 형태로 students 문서에 저장.
class ScheduleRepository {
  ScheduleRepository(this._db);
  final FirebaseFirestore _db;

  /// 학생의 반복 스케줄(요일→시간)을 통째로 갱신(merge).
  /// scheduledDays(요일 키 배열)도 함께 저장해 일관성 유지.
  Future<void> setSchedule(String studentId, Map<String, String> schedule) {
    return _db.collection('students').doc(studentId).set(
      {
        'schedule': schedule,
        'scheduledDays': schedule.keys.toList(),
      },
      SetOptions(merge: true),
    );
  }
}
