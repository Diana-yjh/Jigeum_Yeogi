import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/shared/widgets/placeholder_screen.dart';

/// 학부모 홈 — 내 아이 라이브 상태 카드, 주간 통계, 채팅 미리보기 (Phase 3에서 구현).
class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.favorite_outline,
      title: '학부모 홈',
      description: '우리 아이의 실시간 등하원 상태가\n여기에 표시됩니다. (Phase 3)',
    );
  }
}
