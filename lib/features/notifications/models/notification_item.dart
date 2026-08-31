import 'package:jigeum_yeogi/models/attendance_record.dart';

/// 알림 종류. 현재 학부모에게 가는 푸시는 등원/하원 두 가지뿐이다.
enum NotificationKind { checkIn, checkOut }

/// 지난 알림 한 건.
///
/// 별도 컬렉션에 쌓지 않고 `attendance` 기록의 등원·하원 시각에서 만들어낸다.
/// 문구는 실제 발송을 담당하는 `functions/index.js`의 onAttendanceWrite와
/// 같게 유지한다.
class NotificationItem {
  const NotificationItem({
    required this.studentId,
    required this.studentName,
    required this.kind,
    required this.at,
  });

  final String studentId;
  final String studentName;
  final NotificationKind kind;
  final DateTime at;

  String get title => kind == NotificationKind.checkIn ? '등원 알림' : '하원 알림';

  String get body => kind == NotificationKind.checkIn
      ? '$studentName 학생이 등원했어요.'
      : '$studentName 학생이 하원했어요.';
}

/// 출석 기록을 알림 목록으로 펼친다(최신순).
///
/// [studentNames]는 studentId → 이름. 자녀가 지워졌거나 아직 안 불러온 경우
/// Cloud Functions와 같은 기본값("우리 아이")을 쓴다.
List<NotificationItem> buildNotifications(
  List<AttendanceRecord> records,
  Map<String, String> studentNames,
) {
  final items = <NotificationItem>[];
  for (final r in records) {
    final name = studentNames[r.studentId] ?? '우리 아이';
    final checkIn = r.checkInAt;
    if (checkIn != null) {
      items.add(NotificationItem(
        studentId: r.studentId,
        studentName: name,
        kind: NotificationKind.checkIn,
        at: checkIn,
      ));
    }
    final checkOut = r.checkOutAt;
    if (checkOut != null) {
      items.add(NotificationItem(
        studentId: r.studentId,
        studentName: name,
        kind: NotificationKind.checkOut,
        at: checkOut,
      ));
    }
  }
  items.sort((a, b) => b.at.compareTo(a.at));
  return items;
}
