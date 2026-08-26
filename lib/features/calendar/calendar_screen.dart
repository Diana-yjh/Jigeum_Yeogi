import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/shared/widgets/placeholder_screen.dart';

/// 출결 달력 — 월 달력 + 날짜별 상세 (Phase 4에서 구현).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.calendar_month_outlined,
      title: '출결 달력',
      description: '월별 등하원 기록이\n여기에 표시됩니다. (Phase 4)',
    );
  }
}
