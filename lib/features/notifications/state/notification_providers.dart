import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/features/notifications/models/notification_item.dart';
import 'package:jigeum_yeogi/models/student.dart';

/// 알림함에 보관하는 기간. 이보다 오래된 등하원 기록은 달력에서 본다.
const notificationHistoryDays = 30;

/// 지난 알림 목록(최신순). 자녀 전체를 합쳐 보여준다.
///
/// `parentUid + date` 복합 인덱스를 그대로 쓰므로 인덱스 추가가 필요 없다.
final notificationHistoryProvider =
    StreamProvider<List<NotificationItem>>((ref) {
  final uid = ref.watch(appUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);

  final children = ref.watch(childrenProvider).value ?? const <Student>[];
  final names = {for (final s in children) s.id: s.name};

  final now = DateTime.now();
  final from = dateKey(now.subtract(const Duration(days: notificationHistoryDays)));
  return ref
      .watch(attendanceRepositoryProvider)
      .childRecordsBetween(uid, from, dateKey(now))
      .map((records) => buildNotifications(records, names));
});

/// 마지막으로 알림함을 연 시각. null이면 한 번도 연 적 없음.
final notificationSeenAtProvider = Provider<DateTime?>((ref) {
  return ref.watch(appUserProvider).value?.notificationsSeenAt;
});

/// 마지막으로 알림함을 연 시점 이후에 생긴 알림 수(벨 배지).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationHistoryProvider).value ?? const [];
  final seenAt = ref.watch(notificationSeenAtProvider);
  if (seenAt == null) return items.length;
  return items.where((i) => i.at.isAfter(seenAt)).length;
});

/// 알림함을 열었을 때 호출 — 이후로는 읽음 처리된다.
final markNotificationsSeenProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final uid = ref.read(appUserProvider).value?.uid;
    if (uid == null) return;
    await ref.read(authRepositoryProvider).updateUserFields(
      uid,
      {'notificationsSeenAt': Timestamp.fromDate(DateTime.now())},
    );
  };
});
