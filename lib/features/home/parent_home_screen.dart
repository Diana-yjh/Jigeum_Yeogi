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
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/shared/widgets/status_pill.dart';
import 'package:jigeum_yeogi/shared/widgets/app_background.dart';

/// [directory]의 정렬 순서와 저장된 사용자 지정 색으로 선생님 색을 정한다.
/// 선생님이 1명뿐이거나 연결이 없으면 null(기본 코랄 유지).
Color? _teacherColorFor(
    AppUser? user, Map<String, String> directory, String code) {
  if (directory.length < 2 || !directory.containsKey(code)) return null;
  return AppColors.teacherColor(
    stored: user?.teacherColors[code],
    index: directory.keys.toList().indexOf(code),
  );
}

/// 학부모 홈 — "우리 아이가 지금 어디 있는지"가 1초 안에 읽히는 화면.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const [];

    // 수강 2건 이상이면 한눈에 보이는 리스트 — 카드 탭으로 상세(타임라인·주간) 펼침.
    if (children.length >= 2) {
      return AppScaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xl),
            children: [
              const _Header(name: '우리 아이들'),
              const SizedBox(height: AppSpace.lg),
              for (final c in children) ...[
                _EnrollmentTile(child: c),
                const SizedBox(height: AppSpace.md),
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
    final appUser = ref.watch(appUserProvider).value;
    final directory =
        appUser?.teacherDirectory(children.map((c) => c.teacherCode)) ??
            const <String, String>{};
    final tint = child == null
        ? null
        : _teacherColorFor(appUser, directory, child.teacherCode);

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xl),
          children: [
            _Header(name: child?.name ?? '연결된 자녀 없음'),
            const SizedBox(height: AppSpace.lg),
            if (child != null && directory.length >= 2) ...[
              _TeacherChip(
                  directory: directory, code: child.teacherCode, color: tint),
              const SizedBox(height: AppSpace.sm),
            ],
            _HeroCard(record: today, tint: tint),
            const SizedBox(height: AppSpace.md),
            _WeekCard(child: child, week: week),
          ],
        ),
      ),
    );
  }
}

/// 수강 한 건의 컴팩트 상태 카드 — 탭하면 아래로 타임라인·주간 카드가 펼쳐진다.
/// 수업 중이면 선생님 색 그라디언트, 그 외엔 흰 카드.
class _EnrollmentTile extends ConsumerStatefulWidget {
  final Student child;
  const _EnrollmentTile({required this.child});

  @override
  ConsumerState<_EnrollmentTile> createState() => _EnrollmentTileState();
}

class _EnrollmentTileState extends ConsumerState<_EnrollmentTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final record = ref.watch(studentTodayRecordProvider(child.id)).value;
    final week = (ref.watch(childWeekRecordsProvider).value ?? const [])
        .where((r) => r.studentId == child.id)
        .toList();
    final children = ref.watch(childrenProvider).value ?? const <Student>[];
    final appUser = ref.watch(appUserProvider).value;
    final directory =
        appUser?.teacherDirectory(children.map((c) => c.teacherCode)) ??
            const <String, String>{};
    final tint = _teacherColorFor(appUser, directory, child.teacherCode);

    final checkIn = record?.checkInAt;
    final checkOut = record?.checkOutAt;
    final hasIn = checkIn != null;
    final hasOut = checkOut != null;
    final inClass = hasIn && !hasOut;

    final String pill;
    final String subtitle;
    if (hasOut) {
      pill = '하원 완료';
      subtitle = '${clock(checkIn!)} 등원 → ${clock(checkOut)} 하원';
    } else if (hasIn) {
      pill = '학원에 있어요';
      subtitle = '${clock(checkIn)}부터 학원에 있어요';
    } else {
      pill = '등원 전';
      subtitle = '아직 등원 전이에요';
    }

    final accent = tint ?? AppColors.primary;
    final onColor = inClass ? Colors.white : AppColors.textMain;
    final subColor = inClass ? Colors.white70 : AppColors.textSub;
    final teacherLabel =
        directory.length >= 2 ? directory[child.teacherCode] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => setState(() => _open = !_open),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: inClass
                  ? AppDecoration.hero(tint: tint)
                  : AppDecoration.card(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: inClass
                        ? Colors.white24
                        : accent.withValues(alpha: 0.14),
                    child: Text(child.name.characters.first,
                        style: AppText.cardTitle.copyWith(
                            color: inClass ? Colors.white : accent)),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(child.name,
                                  style: AppText.cardTitle
                                      .copyWith(color: onColor),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            // 선생님이 여럿이면 어느 반인지 색·닉네임으로.
                            if (teacherLabel != null) ...[
                              const SizedBox(width: AppSpace.sm),
                              Flexible(
                                child: Text(teacherLabel,
                                    style: AppText.caption.copyWith(
                                        color: inClass
                                            ? Colors.white70
                                            : accent,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: AppText.caption.copyWith(color: subColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  inClass
                      ? StatusPill.onHero(pill)
                      : StatusPill(
                          label: pill,
                          background: hasOut
                              ? AppColors.chipNeutral
                              : accent.withValues(alpha: 0.14),
                          foreground:
                              hasOut ? AppColors.textSub : accent,
                        ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more,
                        size: 20,
                        color: inClass ? Colors.white70 : AppColors.textFaint),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 펼침 — 타임라인 히어로 + 이번 주 출석(기존 그대로).
        if (_open) ...[
          const SizedBox(height: AppSpace.sm),
          _HeroCard(record: record, tint: tint),
          const SizedBox(height: AppSpace.sm),
          _WeekCard(child: child, week: week),
        ],
      ],
    );
  }
}

/// 소속 선생님 칩 — 선생님 순서에 따른 색 도트 + 닉네임.
/// 색은 [AppUser.teacherDirectory]의 정렬된 키 순서로 배정해 화면 간에 흔들리지 않는다.
class _TeacherChip extends StatelessWidget {
  final Map<String, String> directory;
  final String code;
  final Color? color; // 선생님 구분색(사용자 지정 반영). null이면 연결 없음
  const _TeacherChip(
      {required this.directory, required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    final unlinked = color == null;
    final label = unlinked ? '연결된 선생님 없음' : directory[code]!;

    // 눈에 띄게 — 구분색으로 꽉 채운 pill + 흰 글자.
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? AppColors.chipNeutral,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: AppText.caption.copyWith(
              color: unlinked ? AppColors.textSub : Colors.white,
              fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis),
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
  final Color? tint; // 선생님 구분색 — 있으면 카드 그라디언트를 이 색으로
  const _HeroCard({required this.record, this.tint});

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
      decoration: AppDecoration.hero(tint: tint),
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

    // 원은 "수업이 있는 날"에만 그린다 — 그래야 원 개수가 주당 수업 횟수와 같다.
    // 채워진 원은 출석 하나뿐. 안 온 날은 빈 원 + ×, 오늘은 라벨 색으로만 구분.
    Widget circle;
    Color labelColor = AppColors.textSub;
    if (attended) {
      circle = _circle(
          bg: AppColors.primary,
          child: const Icon(Icons.check, size: 15, color: Colors.white));
      labelColor = AppColors.primaryDeep;
    } else if (isScheduled && isToday) {
      circle = _circle(border: Border.all(color: AppColors.primary, width: 2));
      labelColor = AppColors.primaryDeep;
    } else if (isScheduled && isPast) {
      circle = _circle(
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          child: const Icon(Icons.close, size: 13, color: AppColors.textFaint));
    } else if (isScheduled) {
      circle =
          _circle(border: Border.all(color: AppColors.cardBorder, width: 1.5));
    } else {
      circle = const SizedBox(width: 30, height: 30);
      if (isToday) labelColor = AppColors.primaryDeep;
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
