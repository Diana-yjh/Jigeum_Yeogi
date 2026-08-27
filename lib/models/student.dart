import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';

/// Firestore `students/{studentId}` 문서와 매핑되는 학생 모델.
class Student {
  final String id;
  final String name;
  final String teacherCode;
  final String? parentUid;
  final String? classId;

  /// 매주 반복 스케줄. 요일 코드 → 스케줄 항목(시간+유형).
  /// 예: { 'mon': {time:'15:00', type:'regular'}, 'sat': {time:'14:00', type:'makeup'} }
  final Map<String, ScheduleEntry> schedule;

  const Student({
    required this.id,
    required this.name,
    required this.teacherCode,
    this.parentUid,
    this.classId,
    this.schedule = const {},
  });

  /// 등원 예정 요일 코드 목록.
  List<String> get scheduledDays => schedule.keys.toList();

  /// 특정 요일의 등원 시각("HH:mm") — 없으면 null.
  String? timeOn(String dayCode) => schedule[dayCode]?.time;

  /// 특정 요일의 수업 유형 — 없으면 null.
  ClassType? typeOn(String dayCode) => schedule[dayCode]?.type;

  factory Student.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};

    final schedule = <String, ScheduleEntry>{};
    final rawSchedule = map['schedule'];
    if (rawSchedule is Map) {
      // 신규: {day: {time,type}} 또는 레거시 {day: "HH:mm"}.
      rawSchedule.forEach((k, v) => schedule['$k'] = ScheduleEntry.fromValue(v));
    } else if (map['scheduledDays'] is List) {
      // 레거시: 요일 배열만(시간·유형 미설정).
      for (final d in (map['scheduledDays'] as List)) {
        schedule['$d'] = const ScheduleEntry(time: '');
      }
    }

    return Student(
      id: doc.id,
      name: (map['name'] as String?) ?? '',
      teacherCode: (map['teacherCode'] as String?) ?? '',
      parentUid: map['parentUid'] as String?,
      classId: map['classId'] as String?,
      schedule: schedule,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'teacherCode': teacherCode,
        'parentUid': parentUid,
        'classId': classId,
        'schedule': {for (final e in schedule.entries) e.key: e.value.toMap()},
        'scheduledDays': scheduledDays,
      };
}
