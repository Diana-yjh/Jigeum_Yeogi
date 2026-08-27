import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/models/attendance_record.dart';
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
              _StatsRow(records: week),
              const SizedBox(height: AppSpace.md),
              _ChatPreviewPlaceholder(),
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
      decoration: BoxDecoration(
        color: inClass ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
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

/// 주간 요약 통계 2칸.
class _StatsRow extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _StatsRow({required this.records});

  @override
  Widget build(BuildContext context) {
    final present = records.where((r) => r.isCheckedIn).toList();
    final count = present.length;

    String avg = '-';
    if (present.isNotEmpty) {
      final avgMin = present
              .map((r) => r.checkInAt!.toLocal())
              .map((t) => t.hour * 60 + t.minute)
              .reduce((a, b) => a + b) ~/
          present.length;
      final h = avgMin ~/ 60;
      final m = avgMin % 60;
      final ampm = h < 12 ? '오전' : '오후';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      avg = '$ampm $h12:${m.toString().padLeft(2, '0')}';
    }

    return Row(
      children: [
        Expanded(child: _stat('이번 주 출석', '$count회')),
        const SizedBox(width: AppSpace.md),
        Expanded(child: _stat('평균 등원 시각', avg)),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          Text(value, style: AppText.screenTitle.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

/// 새 소식(채팅 미리보기) — Phase 5 연결 예정.
class _ChatPreviewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.chipNeutral,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: AppColors.textSub),
          const SizedBox(width: AppSpace.sm),
          const Expanded(
            child: Text('선생님과의 채팅은 곧 열려요 (Phase 5)',
                style: AppText.caption),
          ),
        ],
      ),
    );
  }
}
