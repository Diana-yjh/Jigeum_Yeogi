import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/models/user_role.dart';
import 'package:jigeum_yeogi/state/session_provider.dart';

/// 시작 화면 — 선생님 / 학부모 역할 선택.
///
/// Phase 1: 선택 시 곧바로 해당 역할 탭으로 진입(더미).
/// Phase 2: 여기서 각 역할의 회원가입/로그인 흐름으로 연결 예정.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('지금여기', style: AppText.screenTitle.copyWith(fontSize: 32)),
              const SizedBox(height: AppSpace.sm),
              const Text(
                '우리 아이가 학원에 잘 도착했는지\n실시간으로 안심하세요',
                style: AppText.caption,
              ),
              const Spacer(),
              _RoleCard(
                icon: Icons.groups_outlined,
                title: '선생님으로 시작',
                subtitle: '반 전체 등하원을 한눈에 관리해요',
                onTap: () => ref
                    .read(currentRoleProvider.notifier)
                    .selectRole(Role.teacher),
              ),
              const SizedBox(height: AppSpace.md),
              _RoleCard(
                icon: Icons.favorite_outline,
                title: '학부모로 시작',
                subtitle: '우리 아이 등하원을 실시간으로 확인해요',
                onTap: () => ref
                    .read(currentRoleProvider.notifier)
                    .selectRole(Role.parent),
              ),
              const SizedBox(height: AppSpace.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryDeep),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle),
                    const SizedBox(height: AppSpace.xs),
                    Text(subtitle, style: AppText.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
