// 지난 알림 목록 — 출석 기록에서 알림 항목을 만들어내는 규칙과 화면 렌더링.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigeum_yeogi/core/theme/app_theme.dart';
import 'package:jigeum_yeogi/features/notifications/models/notification_item.dart';
import 'package:jigeum_yeogi/features/notifications/notification_list_screen.dart';
import 'package:jigeum_yeogi/features/notifications/state/notification_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';

AttendanceRecord _record({
  required String studentId,
  required String date,
  DateTime? checkIn,
  DateTime? checkOut,
}) =>
    AttendanceRecord(
      studentId: studentId,
      date: date,
      teacherCode: '123456',
      parentUid: 'parent-1',
      checkInAt: checkIn,
      checkOutAt: checkOut,
    );

Future<void> _loadFonts() async {
  final loader = FontLoader('GmarketSans');
  for (final p in [
    'assets/fonts/GmarketSansLight.otf',
    'assets/fonts/GmarketSansMedium.otf',
    'assets/fonts/GmarketSansBold.otf',
  ]) {
    loader.addFont(rootBundle.load(p));
  }
  await loader.load();
}

void main() {
  group('buildNotifications', () {
    test('등원·하원 시각이 각각 한 건씩 알림이 되고 최신순으로 정렬된다', () {
      final items = buildNotifications(
        [
          _record(
            studentId: 's1',
            date: '2026-08-30',
            checkIn: DateTime(2026, 8, 30, 15, 2),
            checkOut: DateTime(2026, 8, 30, 17, 30),
          ),
          _record(
            studentId: 's1',
            date: '2026-08-31',
            checkIn: DateTime(2026, 8, 31, 15, 5),
          ),
        ],
        {'s1': '김테스트'},
      );

      expect(items.length, 3);
      // 최신순: 8/31 등원 → 8/30 하원 → 8/30 등원
      expect(items[0].at, DateTime(2026, 8, 31, 15, 5));
      expect(items[1].kind, NotificationKind.checkOut);
      expect(items[2].kind, NotificationKind.checkIn);
    });

    test('등하원 기록이 없는 날은 알림을 만들지 않는다', () {
      final items = buildNotifications(
        [_record(studentId: 's1', date: '2026-08-29')],
        {'s1': '김테스트'},
      );
      expect(items, isEmpty);
    });

    test('문구는 Cloud Functions 발송 문구와 같다', () {
      final items = buildNotifications(
        [
          _record(
            studentId: 's1',
            date: '2026-08-31',
            checkIn: DateTime(2026, 8, 31, 15, 5),
            checkOut: DateTime(2026, 8, 31, 17, 0),
          ),
        ],
        {'s1': '김테스트'},
      );
      final checkOut = items.firstWhere((i) => i.kind == NotificationKind.checkOut);
      final checkIn = items.firstWhere((i) => i.kind == NotificationKind.checkIn);
      expect(checkIn.title, '등원 알림');
      expect(checkIn.body, '김테스트 학생이 등원했어요.');
      expect(checkOut.title, '하원 알림');
      expect(checkOut.body, '김테스트 학생이 하원했어요.');
    });

    test('이름을 모르는 학생은 기본 문구를 쓴다', () {
      final items = buildNotifications(
        [
          _record(
            studentId: 'gone',
            date: '2026-08-31',
            checkIn: DateTime(2026, 8, 31, 15, 5),
          ),
        ],
        const {},
      );
      expect(items.single.body, '우리 아이 학생이 등원했어요.');
    });

    test('자녀 여러 명의 알림이 시간순으로 합쳐진다', () {
      final items = buildNotifications(
        [
          _record(
            studentId: 's1',
            date: '2026-08-31',
            checkIn: DateTime(2026, 8, 31, 15, 0),
          ),
          _record(
            studentId: 's2',
            date: '2026-08-31',
            checkIn: DateTime(2026, 8, 31, 16, 0),
          ),
        ],
        {'s1': '김테스트', 's2': '박테스트'},
      );
      expect(items.map((i) => i.studentName).toList(), ['박테스트', '김테스트']);
    });
  });

  testWidgets('알림 화면 — 목록이 있으면 날짜별로 묶여 표시된다', (tester) async {
    await _loadFonts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 15, 2);
    final yesterday = today.subtract(const Duration(days: 1));

    final items = buildNotifications(
      [
        _record(
          studentId: 's1',
          date: 'today',
          checkIn: today,
          checkOut: today.add(const Duration(hours: 2)),
        ),
        _record(studentId: 's1', date: 'yesterday', checkIn: yesterday),
      ],
      {'s1': '김테스트'},
    );

    var marked = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationHistoryProvider.overrideWith((ref) => Stream.value(items)),
          notificationSeenAtProvider.overrideWith((ref) => null),
          markNotificationsSeenProvider.overrideWith((ref) => () async {
                marked = true;
              }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('어제'), findsOneWidget);
    expect(find.text('등원 알림'), findsNWidgets(2));
    expect(find.text('하원 알림'), findsOneWidget);
    expect(find.text('김테스트 학생이 하원했어요.'), findsOneWidget);
    // 화면을 열면 읽음 처리된다.
    expect(marked, isTrue);
  });

  testWidgets('알림 화면 — 비어 있으면 안내 문구를 보여준다', (tester) async {
    await _loadFonts();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationHistoryProvider
              .overrideWith((ref) => Stream.value(const <NotificationItem>[])),
          notificationSeenAtProvider.overrideWith((ref) => null),
          markNotificationsSeenProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('아직 받은 알림이 없어요'), findsOneWidget);
  });
}
