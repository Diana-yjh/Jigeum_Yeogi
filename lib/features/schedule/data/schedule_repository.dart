import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';

/// 학생 스케줄(매주 반복: 요일별 시간+유형) 처리.
/// schedule: { 'mon': {time:'15:00', type:'regular'}, ... } 형태로 students 문서에 저장.
class ScheduleRepository {
  ScheduleRepository(this._db);
  final FirebaseFirestore _db;

  /// 학생의 반복 스케줄을 통째로 교체.
  /// merge로 저장하면 중첩 맵(schedule)이 키 단위로 병합되어 삭제한 요일이
  /// 남으므로, update로 schedule 맵 전체를 교체한다(학생 문서는 항상 존재).
  Future<void> setSchedule(
      String studentId, Map<String, ScheduleEntry> schedule) {
    return _db.collection('students').doc(studentId).update({
      'schedule': {
        for (final e in schedule.entries) e.key: e.value.toMap(),
      },
      'scheduledDays': schedule.keys.toList(),
    });
  }
}
