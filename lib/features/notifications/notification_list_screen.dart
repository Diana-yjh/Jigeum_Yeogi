import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/notifications/models/notification_item.dart';
import 'package:jigeum_yeogi/features/notifications/state/notification_providers.dart';
import 'package:jigeum_yeogi/shared/widgets/app_background.dart';

/// 지난 알림 목록(학부모). 홈의 벨 아이콘으로 진입한다.
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  /// 화면에 들어온 시점의 읽음 기준. 여기서 갱신해버리면 이번에 새로 온
  /// 알림까지 즉시 읽음 처리되어 표시가 사라지므로, 진입 시각을 붙잡아 둔다.
  DateTime? _seenAtOnOpen;

  @override
  void initState() {
    super.initState();
    _seenAtOnOpen = ref.read(notificationSeenAtProvider);
    // 목록을 연 시점부터 읽음 처리.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markNotificationsSeenProvider)();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationHistoryProvider);

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('알림', style: AppText.cardTitle),
        iconTheme: const IconThemeData(color: AppColors.textSub),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const _Empty(message: '알림을 불러오지 못했어요.'),
        data: (items) {
          if (items.isEmpty) {
            return const _Empty(
              message: '아직 받은 알림이 없어요.\n등하원 체크가 되면 여기에 쌓입니다.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpace.md),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final showHeader =
                  i == 0 || !_sameDay(items[i - 1].at, item.at);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) ...[
                    if (i != 0) const SizedBox(height: AppSpace.md),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: AppSpace.xs, bottom: AppSpace.sm),
                      child: Text(_dayLabel(item.at), style: AppText.caption),
                    ),
                  ],
                  _NotificationTile(
                    item: item,
                    isNew: _seenAtOnOpen == null ||
                        item.at.isAfter(_seenAtOnOpen!),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '어제';
  return '${t.month}월 ${t.day}일 (${weekdayLabelOf(t)})';
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.isNew});

  final NotificationItem item;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final isCheckIn = item.kind == NotificationKind.checkIn;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckIn ? Icons.login : Icons.logout,
              size: 20,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.title,
                          style: AppText.cardTitle,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.body, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(clock(item.at), style: AppText.caption),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none,
                size: 40, color: AppColors.textFaint),
            const SizedBox(height: AppSpace.md),
            Text(message, textAlign: TextAlign.center, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}
