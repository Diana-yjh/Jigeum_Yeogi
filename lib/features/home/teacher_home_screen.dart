import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
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

    final checkedIn = scheduled
        .where((s) => recById[s.id]?.isCheckedIn == true)
        .length;
    final todayKey = ref.watch(todayKeyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${today.month}월 ${today.day}일 ${weekdayLabelOf(today)}요일',
                  style: AppText.caption),
              const SizedBox(height: AppSpace.xs),
              Text('오늘 등원 예정', style: AppText.screenTitle),
              const SizedBox(height: AppSpace.md),
              _ProgressCard(
                total: scheduled.length,
                checkedIn: checkedIn,
              ),
              const SizedBox(height: AppSpace.md),
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
  Future<void> _confirmReset(
      BuildContext context, WidgetRef ref, String studentId, String date) async {
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

class _ProgressCard extends StatelessWidget {
  final int total;
  final int checkedIn;
  const _ProgressCard({required this.total, required this.checkedIn});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : checkedIn / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('등원 현황',
              style: AppText.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpace.xs),
          Text('$checkedIn / $total명 등원',
              style: AppText.screenTitle.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

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

    String status;
    Color color;
    if (done) {
      status = '하원 완료';
      color = AppColors.textSub;
    } else if (inClass) {
      status = '${formatKoreanTime(r!.checkInAt!)} 등원';
      color = AppColors.primaryDeep;
    } else {
      status = '등원 전';
      color = AppColors.textFaint;
    }

    final timeLabel = (scheduledTime != null && scheduledTime!.isNotEmpty)
        ? formatHhmm(scheduledTime!)
        : '시간 미정';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        // 하원 완료 상태에서만 탭 → 기록 초기화.
        onTap: done ? onReset : null,
        child: Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySoft,
            child: Text(name.characters.first,
                style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppText.body),
                    if (isMakeup) ...[
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.chipNeutral,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('보충',
                            style: AppText.caption
                                .copyWith(color: AppColors.textSub)),
                      ),
                    ],
                  ],
                ),
                Text('등원 예정 $timeLabel', style: AppText.caption),
              ],
            ),
          ),
          Text(status, style: AppText.caption.copyWith(color: color)),
          if (done) ...[
            const SizedBox(width: 6),
            const Icon(Icons.refresh, size: 16, color: AppColors.textFaint),
          ],
        ],
      ),
        ),
      ),
    );
  }
}
