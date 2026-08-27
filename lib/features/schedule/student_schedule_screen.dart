import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/time_format.dart';
import 'package:jigeum_yeogi/features/schedule/state/schedule_providers.dart';
import 'package:jigeum_yeogi/models/schedule_entry.dart';
import 'package:jigeum_yeogi/models/student.dart';

const _defaultSlot = '15:00';

/// 학생 한 명의 스케줄 편집 화면 — 요일별 시간 + 정규/보충.
class StudentScheduleScreen extends ConsumerStatefulWidget {
  final Student student;
  const StudentScheduleScreen({super.key, required this.student});

  @override
  ConsumerState<StudentScheduleScreen> createState() =>
      _StudentScheduleScreenState();
}

class _StudentScheduleScreenState
    extends ConsumerState<StudentScheduleScreen> {
  late final Map<String, ScheduleEntry> _schedule = {
    ...widget.student.schedule,
  };
  bool _saving = false;

  void _toggleDay(String code, bool on) {
    setState(() {
      if (on) {
        _schedule[code] = const ScheduleEntry(time: _defaultSlot);
      } else {
        _schedule.remove(code);
      }
    });
  }

  void _setTime(String code, String time) {
    setState(() => _schedule[code] =
        (_schedule[code] ?? const ScheduleEntry(time: _defaultSlot))
            .copyWith(time: time));
  }

  void _setType(String code, ClassType type) {
    setState(() => _schedule[code] =
        (_schedule[code] ?? const ScheduleEntry(time: _defaultSlot))
            .copyWith(type: type));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(scheduleRepositoryProvider)
          .setSchedule(widget.student.id, _schedule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스케줄을 저장했어요.')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 문제가 발생했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textMain,
        title: Text('${widget.student.name} 스케줄'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            const Text('수업 요일과 시간, 정규/보충을 설정하세요.',
                style: AppText.caption),
            const SizedBox(height: AppSpace.md),
            for (var d = 0; d < 7; d++) _dayCard(d),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              shape: const StadiumBorder(),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('저장'),
          ),
        ),
      ),
    );
  }

  Widget _dayCard(int dayIndex) {
    final code = weekdayCodes[dayIndex];
    final entry = _schedule[code];
    final on = entry != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${weekdayLabels[dayIndex]}요일',
                  style: AppText.cardTitle),
              const Spacer(),
              Switch(
                value: on,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => _toggleDay(code, v),
              ),
            ],
          ),
          if (on) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                const Text('시간', style: AppText.caption),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: DropdownButton<String>(
                    value: scheduleTimeSlots.contains(entry.time)
                        ? entry.time
                        : null,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('시간 선택', style: AppText.caption),
                    items: [
                      for (final slot in scheduleTimeSlots)
                        DropdownMenuItem(
                          value: slot,
                          child: Text(formatHhmm(slot), style: AppText.body),
                        ),
                    ],
                    onChanged: (t) {
                      if (t != null) _setTime(code, t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                const Text('유형', style: AppText.caption),
                const SizedBox(width: AppSpace.md),
                _typeChip(code, ClassType.regular, entry.type),
                const SizedBox(width: AppSpace.sm),
                _typeChip(code, ClassType.makeup, entry.type),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(String code, ClassType type, ClassType selected) {
    final on = type == selected;
    return GestureDetector(
      onTap: () => _setType(code, type),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.chipNeutral,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          type.label,
          style: AppText.caption.copyWith(
            color: on ? Colors.white : AppColors.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
