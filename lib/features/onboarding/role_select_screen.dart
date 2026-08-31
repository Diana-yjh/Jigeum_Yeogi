import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/features/auth/onboarding/auth_screen.dart';
import 'package:jigeum_yeogi/models/user_role.dart';
import 'package:jigeum_yeogi/shared/widgets/app_background.dart';

/// 시작 화면 — 선생님 / 학부모 역할 선택 후 해당 역할의 로그인/회원가입으로 이동.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  void _goAuth(BuildContext context, Role role) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // 로고 — 이미지 자체에 둥근 모서리가 있어 그림자만 얹는다.
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadow.soft,
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text('지금여기', style: AppText.display.copyWith(fontSize: 36)),
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
                onTap: () => _goAuth(context, Role.teacher),
              ),
              const SizedBox(height: AppSpace.md),
              _RoleCard(
                icon: Icons.favorite_outline,
                title: '학부모로 시작',
                subtitle: '우리 아이 등하원을 실시간으로 확인해요',
                onTap: () => _goAuth(context, Role.parent),
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          decoration: AppDecoration.card(),
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
