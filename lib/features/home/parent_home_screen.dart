import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';

/// 학부모 홈 — 내 아이 라이브 상태 카드 + 주간 요약.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childProvider).value;
    final record = ref.watch(childTodayRecordProvider).value;
    final week = ref.watch(childWeekRecordsProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('우리 아이', style: AppText.caption),
              const SizedBox(height: AppSpace.xs),
              Text(child?.name ?? '연결된 자녀 없음', style: AppText.screenTitle),
              const SizedBox(height: AppSpace.lg),
              _LiveCard(child: child, record: record),
              const SizedBox(height: AppSpace.md),
              _WeeklyRecords(child: child, records: week),
            ],
          ),
        ),
      ),
    );
  }
}

/// 내 아이 라이브 상태 카드 — 화면의 중심.
class _LiveCard extends StatelessWidget {
  final Student? child;
  final AttendanceRecord? record;
  const _LiveCard({required this.child, required this.record});

  @override
  Widget build(BuildContext context) {
    final inClass =
        record?.isCheckedIn == true && record?.isCheckedOut != true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: inClass ? AppDecoration.hero() : AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBadge(inClass),
          const SizedBox(height: AppSpace.md),
          Text(
            _title(),
            style: AppText.sectionTitle.copyWith(
              color: inClass ? Colors.white : AppColors.textMain,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _subtitle(),
            style: AppText.caption.copyWith(
              color: inClass ? Colors.white70 : AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool inClass) {
    final label = _badgeLabel();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: inClass ? Colors.white24 : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle,
              size: 8,
              color: inClass ? Colors.white : AppColors.primaryDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.caption.copyWith(
              color: inClass ? Colors.white : AppColors.primaryDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _badgeLabel() {
    if (child == null) return '대기 중';
    if (record?.isCheckedOut == true) return '하원 완료';
    if (record?.isCheckedIn == true) return '학원에 있어요';
    if (record?.status == AttendanceStatus.expectedAbsent) return '결석 예정';
    return '등원 전';
  }

  String _title() {
    if (child == null) return '아직 연결된 자녀가 없어요';
    if (record?.isCheckedOut == true) return '오늘 하원했어요';
    if (record?.isCheckedIn == true) return '지금 학원에 있어요';
    if (record?.status == AttendanceStatus.expectedAbsent) {
      return '오늘은 결석 예정이에요';
    }
    return '아직 등원 전이에요';
  }

  String _subtitle() {
    if (child == null) return '가입 시 입력한 자녀가 곧 연결됩니다.';
    final r = record;
    if (r == null || (!r.isCheckedIn)) return '등원하면 알려드릴게요.';
    if (r.isCheckedOut) {
      final stay = r.stayDuration;
      final stayText = stay != null ? ' · 총 ${formatDuration(stay)}' : '';
      return '${formatKoreanTime(r.checkInAt!)} 등원 → '
          '${formatKoreanTime(r.checkOutAt!)} 하원$stayText';
    }
    // 등원 후 수업 중
    final elapsed = DateTime.now().difference(r.checkInAt!);
    return '${formatKoreanTime(r.checkInAt!)} 등원 · ${formatDuration(elapsed)}째 수업 중';
  }
}

/// 주간 출석 기록 — 이번 주 출석 횟수 + 요일·날짜·등하원 시간·정규/보충.
class _WeeklyRecords extends StatelessWidget {
  final Student? child;
  final List<AttendanceRecord> records;
  const _WeeklyRecords({required this.child, required this.records});

  @override
  Widget build(BuildContext context) {
    final present = records.where((r) => r.isCheckedIn).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('이번 주 출석', style: AppText.caption),
              Text('${present.length}회',
                  style: AppText.cardTitle
                      .copyWith(color: AppColors.primaryDeep)),
            ],
          ),
          if (present.isEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            const Text('이번 주 출석 기록이 없어요.', style: AppText.caption),
          ] else
            for (final r in present) ...[
              const Divider(height: AppSpace.lg, color: AppColors.cardBorder),
              _recordRow(r),
            ],
        ],
      ),
    );
  }

  Widget _recordRow(AttendanceRecord r) {
    final date = DateTime.parse(r.date);
    final dow = weekdayLabelOf(date);
    final md = '${date.month}/${date.day}';
    final inT = formatKoreanTime(r.checkInAt!);
    final outT =
        r.checkOutAt != null ? formatKoreanTime(r.checkOutAt!) : '수업 중';
    final isMakeup =
        (child?.typeOn(weekdayCodeOf(date)) ?? ClassType.regular) ==
            ClassType.makeup;

    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text('$dow $md', style: AppText.body),
        ),
        Expanded(
          child: Text('$inT → $outT', style: AppText.caption),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isMakeup ? AppColors.primarySoft : AppColors.sageSoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            isMakeup ? '보충' : '정규',
            style: AppText.caption.copyWith(
                color: isMakeup ? AppColors.primaryDeep : AppColors.sageDeep,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
