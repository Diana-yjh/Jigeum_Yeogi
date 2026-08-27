import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

/// 설정 화면.
/// - 프로필(이름/역할) 표시
/// - 선생님: 6자리 코드 표시(변경 불가) — 학부모 초대에 사용
/// - 로그아웃
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final roleLabel = user?.role == Role.teacher ? '선생님' : '학부모';

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
              _InfoCard(
                title: '내 정보',
                children: [
                  _row('이름', user?.name ?? '-'),
                  _row('역할', roleLabel),
                  _row('이메일', user?.email ?? '-'),
                ],
              ),
              if (user?.role == Role.teacher) ...[
                const SizedBox(height: AppSpace.md),
                _TeacherCodeCard(code: user?.teacherCode ?? '------'),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmSignOut(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDeep,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('로그아웃'),
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ),
    );
  }

  /// 로그아웃 전 확인 알림.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.caption),
          Text(value, style: AppText.body),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: AppSpace.sm),
          ...children,
        ],
      ),
    );
  }
}

/// 선생님 6자리 코드 카드 — 학부모 가입 시 전달하는 값. 변경 불가.
class _TeacherCodeCard extends StatelessWidget {
  final String code;
  const _TeacherCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('우리 반 코드', style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          Text(
            code,
            style: AppText.screenTitle.copyWith(
              color: AppColors.primaryDeep,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          const Text('학부모님께 이 코드를 알려주세요', style: AppText.caption),
        ],
      ),
    );
  }
}
