import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';

/// 학생 스케줄(매주 반복: 요일별 시간+유형) 처리.
/// schedule: { 'mon': {time:'15:00', type:'regular'}, ... } 형태로 students 문서에 저장.
class ScheduleRepository {
  ScheduleRepository(this._db);
  final FirebaseFirestore _db;

  /// 학생의 반복 스케줄을 통째로 갱신(merge).
  /// scheduledDays(요일 키 배열)도 함께 저장해 일관성 유지.
  Future<void> setSchedule(
      String studentId, Map<String, ScheduleEntry> schedule) {
    return _db.collection('students').doc(studentId).set(
      {
        'schedule': {
          for (final e in schedule.entries) e.key: e.value.toMap(),
        },
        'scheduledDays': schedule.keys.toList(),
      },
      SetOptions(merge: true),
    );
  }
}
