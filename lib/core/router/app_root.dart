import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/features/onboarding/role_select_screen.dart';
import 'package:jigeum_yeogi/features/shell/main_tab_screen.dart';
import 'package:jigeum_yeogi/shared/widgets/splash_screen.dart';

/// 인증 상태 기반 라우팅 루트.
///
/// - 로그인 안 됨 → 시작 화면(역할 선택 → 로그인/회원가입)
/// - 로그인 됨 → users 프로필 로드 → 역할별 탭 셸
/// - 로딩/프로필 준비 중 → 스플래시
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const SplashScreen(message: '지금여기'),
      error: (_, _) =>
          const SplashScreen(message: '연결에 문제가 있어요. 앱을 다시 실행해주세요.'),
      data: (authUser) {
        if (authUser == null) {
          return const RoleSelectScreen();
        }
        // 로그인됨 → Firestore 프로필(역할) 로드.
        final appUserAsync = ref.watch(appUserProvider);
        return appUserAsync.when(
          loading: () => const SplashScreen(message: '프로필을 불러오는 중...'),
          error: (_, _) => const SplashScreen(message: '프로필을 불러오지 못했어요.'),
          data: (user) {
            if (user == null) {
              // 가입 직후 문서 생성 대기 등 — 잠시 스플래시.
              return const SplashScreen(message: '준비 중...');
            }
            return MainTabScreen(role: user.role);
          },
        );
      },
    );
  }
}
