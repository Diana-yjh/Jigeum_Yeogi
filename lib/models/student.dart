import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `students/{studentId}` 문서와 매핑되는 학생 모델.
class Student {
  final String id;
  final String name;
  final String teacherCode;
  final String? parentUid;
  final String? classId;

  /// 매주 반복 스케줄. 요일 코드 → 등원 시각("HH:mm").
  /// 예: { 'mon': '15:00', 'wed': '16:30' }
  final Map<String, String> schedule;

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
  String? timeOn(String dayCode) => schedule[dayCode];

  factory Student.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};

    // 신규: schedule 맵. 레거시: scheduledDays 배열(시간 없음).
    final rawSchedule = map['schedule'];
    final schedule = <String, String>{};
    if (rawSchedule is Map) {
      rawSchedule.forEach((k, v) => schedule['$k'] = '$v');
    } else if (map['scheduledDays'] is List) {
      for (final d in (map['scheduledDays'] as List)) {
        schedule['$d'] = ''; // 시간 미설정
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
        'schedule': schedule,
        'scheduledDays': scheduledDays,
      };
}
