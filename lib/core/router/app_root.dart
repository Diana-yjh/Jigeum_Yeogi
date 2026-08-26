import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/features/onboarding/role_select_screen.dart';
import 'package:jigeum_yeogi/features/shell/main_tab_screen.dart';
import 'package:jigeum_yeogi/state/session_provider.dart';

/// 역할 분기용 라우팅 골격.
///
/// 역할이 없으면 시작 화면(선생님/학부모 선택),
/// 역할이 정해지면 해당 역할용 탭 셸을 보여준다.
/// Phase 2에서 로그인/온보딩 라우트가 이 사이에 끼어들 예정.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);

    if (role == null) {
      return const RoleSelectScreen();
    }
    return MainTabScreen(role: role);
  }
}
