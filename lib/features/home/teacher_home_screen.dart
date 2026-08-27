import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/schedule/state/schedule_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';

/// 선생님 홈 — 오늘 등원 예정 아이들과 등원 현황.
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayCode = weekdayCodeOf(today);
    final scheduled = ref.watch(todayScheduledStudentsProvider);
    final records = ref.watch(teacherTodayRecordsProvider).value ?? const [];
    final recById = {for (final r in records) r.studentId: r};

    final checkedIn =
        scheduled.where((s) => recById[s.id]?.isCheckedIn == true).length;
    final todayKey = ref.watch(todayKeyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.md, AppSpace.md, AppSpace.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${today.month}월 ${today.day}일 ${weekdayLabelOf(today)}요일',
                  style: AppText.caption),
              const SizedBox(height: AppSpace.xs),
              Text('오늘 등원 예정', style: AppText.screenTitle),
              const SizedBox(height: AppSpace.lg),
              _ProgressCard(total: scheduled.length, checkedIn: checkedIn),
              const SizedBox(height: AppSpace.lg),
              Expanded(
                child: scheduled.isEmpty
                    ? const Center(
                        child: Text(
                          '오늘 등원 예정인 학생이 없어요.\n스케줄 탭에서 요일을 지정해보세요.',
                          textAlign: TextAlign.center,
                          style: AppText.caption,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpace.lg),
                        itemCount: scheduled.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpace.sm),
                        itemBuilder: (_, i) {
                          final s = scheduled[i];
                          return _ScheduledRow(
                            name: s.name,
                            scheduledTime: s.timeOn(todayCode),
                            isMakeup: s.typeOn(todayCode) == ClassType.makeup,
                            record: recById[s.id],
                            onReset: () =>
                                _confirmReset(context, ref, s.id, todayKey),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 하원 완료 학생 탭 시 기록 초기화 확인.
  Future<void> _confirmReset(BuildContext context, WidgetRef ref,
      String studentId, String date) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 초기화'),
        content: const Text('기록을 초기화 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(attendanceRepositoryProvider).resetRecord(studentId, date);
    }
  }
}

/// 등원 현황 히어로 카드.
class _ProgressCard extends StatelessWidget {
  final int total;
  final int checkedIn;
  const _ProgressCard({required this.total, required this.checkedIn});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : checkedIn / total;
    final remaining = total - checkedIn;
    final String note;
    if (total == 0) {
      note = '오늘 예정이 없어요';
    } else if (remaining == 0) {
      note = '모두 등원했어요 🎉';
    } else {
      note = '$remaining명 등원 전';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecoration.hero(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('오늘 등원 현황',
                  style: AppText.caption.copyWith(color: Colors.white70)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(note,
                    style: AppText.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$checkedIn',
                  style: AppText.display.copyWith(color: Colors.white)),
              Text(' / $total명 등원',
                  style: AppText.cardTitle.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// 예정 학생 행.
class _ScheduledRow extends StatelessWidget {
  final String name;
  final String? scheduledTime; // 오늘 등원 예정 시각("HH:mm")
  final bool isMakeup;
  final AttendanceRecord? record;
  final VoidCallback onReset;
  const _ScheduledRow({
    required this.name,
    required this.scheduledTime,
    required this.isMakeup,
    required this.record,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    final inClass = r?.isCheckedIn == true && r?.isCheckedOut != true;
    final done = r?.isCheckedOut == true;

    final timeLabel = (scheduledTime != null && scheduledTime!.isNotEmpty)
        ? formatHhmm(scheduledTime!)
        : '시간 미정';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: done ? onReset : null, // 하원 완료만 탭 → 기록 초기화
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: AppDecoration.card(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Text(name.characters.first,
                    style: AppText.cardTitle
                        .copyWith(color: AppColors.primaryDeep)),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: AppText.cardTitle),
                        if (isMakeup) ...[
                          const SizedBox(width: AppSpace.sm),
                          _tag('보충', AppColors.primarySoft,
                              AppColors.primaryDeep),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('등원 예정 $timeLabel', style: AppText.caption),
                  ],
                ),
              ),
              _statusChip(inClass: inClass, done: done, record: r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
      {required bool inClass, required bool done, AttendanceRecord? record}) {
    String label;
    Color bg;
    Color fg;
    if (done) {
      label = '하원 완료';
      bg = AppColors.chipNeutral;
      fg = AppColors.textSub;
    } else if (inClass) {
      label = '${clock(record!.checkInAt!)} 등원';
      bg = AppColors.sageSoft;
      fg = AppColors.sageDeep;
    } else {
      label = '등원 전';
      bg = AppColors.primarySoft;
      fg = AppColors.primaryDeep;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tag(label, bg, fg),
        if (done) ...[
          const SizedBox(width: 4),
          const Icon(Icons.refresh, size: 15, color: AppColors.textFaint),
        ],
      ],
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text,
          style: AppText.caption
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
