import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `students/{studentId}` 문서와 매핑되는 학생 모델.
class Student {
  final String id;
  final String name;
  final String teacherCode;
  final String? parentUid;
  final String? classId;
  final List<String> scheduledDays; // 예: ['mon','wed','fri']

  const Student({
    required this.id,
    required this.name,
    required this.teacherCode,
    this.parentUid,
    this.classId,
    this.scheduledDays = const [],
  });

  factory Student.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return Student(
      id: doc.id,
      name: (map['name'] as String?) ?? '',
      teacherCode: (map['teacherCode'] as String?) ?? '',
      parentUid: map['parentUid'] as String?,
      classId: map['classId'] as String?,
      scheduledDays:
          (map['scheduledDays'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'teacherCode': teacherCode,
        'parentUid': parentUid,
        'classId': classId,
        'scheduledDays': scheduledDays,
      };
}
