import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/shared/widgets/placeholder_screen.dart';

/// 채팅 목록 — 선생님↔학부모 1:1 채팅 (Phase 5에서 구현).
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.chat_bubble_outline,
      title: '채팅',
      description: '선생님과 학부모의 1:1 대화가\n여기에 표시됩니다. (Phase 5)',
    );
  }
}
