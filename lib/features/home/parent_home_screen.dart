import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/notifications/notification_list_screen.dart';
import 'package:jigeum_yeogi/features/notifications/state/notification_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/shared/widgets/status_pill.dart';

/// 학부모 홈 — "우리 아이가 지금 어디 있는지"가 1초 안에 읽히는 화면.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const [];

    // 자녀 2명 이상이면 아이별 상태 카드를 나열.
    if (children.length >= 2) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xl),
            children: [
              const _Header(name: '우리 아이들'),
              const SizedBox(height: AppSpace.lg),
              for (final c in children) ...[
                _ChildSection(child: c),
                const SizedBox(height: AppSpace.lg),
              ],
            ],
          ),
        ),
      );
    }

    // 단일 자녀(또는 없음) — 기존 히어로 + 주간 카드.
    final child = children.isNotEmpty ? children.first : null;
    final today = ref.watch(childTodayRecordProvider).value;
    final week = ref.watch(childWeekRecordsProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xl),
          children: [
            _Header(name: child?.name ?? '연결된 자녀 없음'),
            const SizedBox(height: AppSpace.lg),
            _HeroCard(record: today),
            const SizedBox(height: AppSpace.md),
            _WeekCard(child: child, week: week),
          ],
        ),
      ),
    );
  }
}

/// 아이 한 명의 홈 구획(자녀 여러 명일 때).
/// 단일 자녀 화면과 같은 히어로 + 주간 카드를 이름 아래에 그대로 반복한다.
class _ChildSection extends ConsumerWidget {
  final Student child;
  const _ChildSection({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(studentTodayRecordProvider(child.id)).value;
    // 주간 기록은 자녀 전체를 한 번에 받아오므로 이 아이 것만 골라 쓴다.
    final week = (ref.watch(childWeekRecordsProvider).value ?? const [])
        .where((r) => r.studentId == child.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(child.name, style: AppText.sectionTitle),
        const SizedBox(height: AppSpace.sm),
        _HeroCard(record: today),
        const SizedBox(height: AppSpace.md),
        _WeekCard(child: child, week: week),
      ],
    );
  }
}

/// 헤더 — 아바타 + 이름/날짜 + 알림 버튼.
class _Header extends ConsumerWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateText = '${now.month}월 ${now.day}일 ${weekdayLabelOf(now)}요일';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            name.characters.first,
            style: AppText.sectionTitle.copyWith(color: AppColors.primaryDeep),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppText.sectionTitle,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(dateText, style: AppText.caption),
            ],
          ),
        ),
        _NotificationButton(unread: ref.watch(unreadNotificationCountProvider)),
      ],
    );
  }
}

/// 지난 알림 목록으로 가는 종 버튼. 안 읽은 알림이 있으면 점을 띄운다.
class _NotificationButton extends StatelessWidget {
  final int unread;
  const _NotificationButton({required this.unread});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationListScreen()),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none,
                  size: 20, color: AppColors.textSub),
              if (unread > 0)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘 상태 히어로 카드 — 화면에서 유일한 오렌지 면.
class _HeroCard extends StatelessWidget {
  final AttendanceRecord? record;
  const _HeroCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final checkIn = record?.checkInAt;
    final checkOut = record?.checkOutAt;
    final hasIn = checkIn != null;
    final hasOut = checkOut != null;

    final String pill;
    final String title;
    if (hasOut) {
      pill = '하원 완료';
      title = '집에 잘 갔어요';
    } else if (hasIn) {
      pill = '학원에 있어요';
      title = '지금 학원에 있어요';
    } else {
      pill = '등원 전';
      title = '아직 등원 전이에요';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecoration.hero(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill.onHero(pill),
          const SizedBox(height: AppSpace.md),
          Text(title,
              style: AppText.sectionTitle.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpace.lg),
          _Timeline(
              hasIn: hasIn, hasOut: hasOut, checkIn: checkIn, checkOut: checkOut),
          if (hasIn) ...[
            const SizedBox(height: AppSpace.md),
            Center(
              child: Text(
                hasOut
                    ? '${formatDuration(checkOut.difference(checkIn))} 머물렀어요'
                    : '${clock(checkIn)}부터 학원에 있어요',
                style: AppText.caption
                    .copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 히어로 카드 안 등원~하원 타임라인.
class _Timeline extends StatelessWidget {
  final bool hasIn;
  final bool hasOut;
  final DateTime? checkIn;
  final DateTime? checkOut;
  const _Timeline({
    required this.hasIn,
    required this.hasOut,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _end('등원', checkIn),
        const SizedBox(width: AppSpace.sm),
        _dot(hasIn),
        Expanded(child: _line(hasIn)),
        Expanded(child: _line(hasOut)),
        _dot(hasOut),
        const SizedBox(width: AppSpace.sm),
        _end('하원', checkOut),
      ],
    );
  }

  Widget _line(bool filled) {
    const faint = Color(0x40FFFFFF);
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: filled ? Colors.white : faint,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _end(String label, DateTime? t) {
    return Column(
      children: [
        Text(label,
            style: AppText.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 3),
        Text(t != null ? clock(t) : '--:--',
            style: AppText.cardTitle.copyWith(color: Colors.white)),
      ],
    );
  }
}

/// 이번 주 출석 카드 — 월~일 도트.
class _WeekCard extends StatelessWidget {
  final Student? child;
  final List<AttendanceRecord> week;
  const _WeekCard({required this.child, required this.week});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final byDate = {for (final r in week) r.date: r};
    final scheduled = child?.scheduledDays.toSet() ?? <String>{};

    final attendedCount = week.where((r) => r.isCheckedIn).length;
    final denom = scheduled.length;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecoration.card(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('이번 주 출석',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  denom > 0 ? '$attendedCount / $denom회' : '$attendedCount회',
                  style: AppText.caption.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _dayCell(monday.add(Duration(days: i)), i, today, byDate,
                    scheduled),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime date, int i, DateTime today,
      Map<String, AttendanceRecord> byDate, Set<String> scheduled) {
    final code = weekdayCodes[i];
    final attended = byDate[dateKey(date)]?.isCheckedIn == true;
    final isScheduled = scheduled.contains(code);
    final isPast = date.isBefore(today);
    final isToday = date == today;

    Widget circle;
    Color labelColor = AppColors.textSub;
    if (attended) {
      circle = _circle(
          bg: AppColors.primary,
          child: const Icon(Icons.check, size: 15, color: Colors.white));
      labelColor = AppColors.primaryDeep;
    } else if (isToday) {
      circle = _circle(border: Border.all(color: AppColors.primary, width: 2));
      labelColor = AppColors.primaryDeep;
    } else if (isScheduled && isPast) {
      circle = _circle(
          bg: AppColors.chipNeutral,
          child: Text('—',
              style: AppText.caption.copyWith(color: AppColors.textFaint)));
    } else if (isScheduled) {
      circle =
          _circle(border: Border.all(color: AppColors.cardBorder, width: 1.5));
    } else {
      circle = const SizedBox(width: 30, height: 30);
    }

    return Column(
      children: [
        Text(weekdayLabels[i],
            style: AppText.caption.copyWith(color: labelColor)),
        const SizedBox(height: 8),
        circle,
      ],
    );
  }

  Widget _circle({Color? bg, BoxBorder? border, Widget? child}) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: border,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}
