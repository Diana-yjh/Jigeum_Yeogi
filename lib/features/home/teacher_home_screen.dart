import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/shared/widgets/placeholder_screen.dart';

/// 선생님 홈 — 오늘 수업 카드, "확인이 필요해요" 섹션 (Phase 3에서 구현).
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.dashboard_outlined,
      title: '선생님 홈',
      description: '오늘 수업 현황과 확인이 필요한 항목이\n여기에 표시됩니다. (Phase 3)',
    );
  }
}
