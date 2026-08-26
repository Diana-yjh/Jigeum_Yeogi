import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/models/user_role.dart';
import 'package:jigeum_yeogi/state/session_provider.dart';

/// 설정 화면.
/// Phase 1: 현재 역할 표시 + 역할 다시 선택(로그아웃 대용) — 역할 분기 확인용.
/// Phase 2: 선생님 6자리 코드 확인, 계정/알림 설정 등 추가 예정.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final roleLabel = role == Role.teacher ? '선생님' : '학부모';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('설정', style: AppText.screenTitle),
              const SizedBox(height: AppSpace.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.cardBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 역할', style: AppText.caption),
                    const SizedBox(height: AppSpace.xs),
                    Text(roleLabel, style: AppText.cardTitle),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(currentRoleProvider.notifier).clear(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDeep,
                    side: const BorderSide(color: AppColors.primary),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpace.md),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('역할 다시 선택'),
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ),
    );
  }
}
