import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/shared/widgets/status_pill.dart';

/// 학부모 홈 — "우리 아이가 지금 어디 있는지"가 1초 안에 읽히는 화면.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childProvider).value;
    final today = ref.watch(childTodayRecordProvider).value;
    final week = ref.watch(childWeekRecordsProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            _Header(name: child?.name ?? '연결된 자녀 없음'),
            const SizedBox(height: AppSpace.md),
            _HeroCard(record: today),
            const SizedBox(height: AppSpace.md),
            _WeekCard(child: child, week: week),
          ],
        ),
      ),
    );
  }
}

/// 헤더 — 아바타 + 이름 + 종 아이콘.
class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            name.characters.first,
            style: AppText.cardTitle.copyWith(color: AppColors.primaryDeep),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(name,
              style: AppText.sectionTitle, overflow: TextOverflow.ellipsis),
        ),
        const Icon(Icons.notifications_none,
            size: 22, color: AppColors.textSub),
      ],
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

    final now = DateTime.now();
    final dateLabel = '${weekdayLabelOf(now)} ${now.month}/${now.day}';

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.hero(radius: AppRadius.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusPill.onHero(pill),
              Text(dateLabel,
                  style: AppText.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: AppText.cardTitle.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          _Timeline(hasIn: hasIn, hasOut: hasOut, checkIn: checkIn, checkOut: checkOut),
          if (hasIn) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                hasOut
                    ? '${_stayText(checkIn, checkOut)} 머물렀어요'
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

  String _stayText(DateTime inAt, DateTime outAt) =>
      formatDuration(outAt.difference(inAt));
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
    const faint = Color(0x59FFFFFF); // 흰색 35%
    return Row(
      children: [
        _end('등원', checkIn),
        const SizedBox(width: AppSpace.sm),
        _dot(hasIn),
        Expanded(child: Container(height: 3, color: hasIn ? Colors.white : faint)),
        Expanded(child: Container(height: 3, color: hasOut ? Colors.white : faint)),
        _dot(hasOut),
        const SizedBox(width: AppSpace.sm),
        _end('하원', checkOut),
      ],
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  Widget _end(String label, DateTime? t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: AppText.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(t != null ? clock(t) : '--:--',
            style: AppText.body
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('이번 주',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
              Text(denom > 0 ? '$attendedCount / $denom회' : '$attendedCount회',
                  style: AppText.caption),
            ],
          ),
          const SizedBox(height: AppSpace.md),
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

    Widget circle;
    Color labelColor = AppColors.textSub;
    if (attended) {
      circle = _circle(
          bg: AppColors.primary,
          child: const Icon(Icons.check, size: 12, color: Colors.white));
      labelColor = AppColors.primaryDeep;
    } else if (isScheduled && isPast) {
      circle = _circle(
          bg: AppColors.cardBorder,
          child: Text('—',
              style: AppText.caption.copyWith(color: AppColors.textFaint)));
    } else if (isScheduled) {
      circle = _circle(
          border: Border.all(color: AppColors.textFaint, width: 1));
    } else {
      circle = const SizedBox(width: 22, height: 22);
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
      width: 22,
      height: 22,
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
