import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

/// Firestore `users/{uid}` 문서와 매핑되는 앱 사용자 모델.
class AppUser {
  final String uid;
  final Role role;
  final String name;
  final String email;
  final String? teacherCode; // 선생님만 보유하는 6자리 코드
  final String? fcmToken; // 등하원 푸시 발송 대상(Cloud Functions에서 사용)
  final bool notifyCheckIn; // 등원 알림 (기본 on)
  final bool notifyCheckOut; // 하원 알림 (기본 on)

  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.teacherCode,
    this.fcmToken,
    this.notifyCheckIn = true,
    this.notifyCheckOut = true,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      role: (map['role'] as String?) == 'teacher' ? Role.teacher : Role.parent,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      teacherCode: map['teacherCode'] as String?,
      fcmToken: map['fcmToken'] as String?,
      notifyCheckIn: (map['notifyCheckIn'] as bool?) ?? true,
      notifyCheckOut: (map['notifyCheckOut'] as bool?) ?? true,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'role': role == Role.teacher ? 'teacher' : 'parent',
        'name': name,
        'email': email,
        if (teacherCode != null) 'teacherCode': teacherCode,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}
