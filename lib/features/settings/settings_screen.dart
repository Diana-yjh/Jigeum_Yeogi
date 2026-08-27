import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

/// 설정 화면 — 역할별 분기(학부모/선생님).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    if (user == null) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    return user.role == Role.teacher
        ? _TeacherSettings(user: user)
        : const _ParentSettings();
  }
}

// ── 공용 확인/조각 ─────────────────────────────────────────
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('로그아웃'),
      content: const Text('로그아웃 하시겠습니까?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
          child: const Text('로그아웃'),
        ),
      ],
    ),
  );
  if (ok == true) await ref.read(authRepositoryProvider).signOut();
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 6),
        child: Text(text, style: AppText.caption),
      );
}

/// 카드 안 행들 사이 1px 구분선(첫 행 제외).
class _RowsCard extends StatelessWidget {
  final List<Widget> rows;
  const _RowsCard(this.rows);
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, color: AppColors.cardBorder));
      }
      children.add(rows[i]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: AppDecoration.card(),
      child: Column(children: children),
    );
  }
}

// ── 학부모 설정 ────────────────────────────────────────────
class _ParentSettings extends ConsumerWidget {
  const _ParentSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value!;
    final child = ref.watch(childProvider).value;

    void toggleNotify(String key, bool v) {
      ref
          .read(authRepositoryProvider)
          .updateUserFields(user.uid, {key: v}).catchError((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('설정 저장에 실패했어요.')));
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            const Text('설정',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain)),
            const SizedBox(height: AppSpace.md),
            _profileCard(user),
            const SizedBox(height: AppSpace.md),
            const _SectionLabel('우리 아이'),
            _RowsCard([
              _childRow(child?.name ?? '연결된 자녀 없음'),
              _codeRow(context, child?.teacherCode ?? '------'),
              _addChildRow(context),
            ]),
            const SizedBox(height: AppSpace.md),
            const _SectionLabel('알림'),
            _RowsCard([
              _toggleRow('등원 알림', user.notifyCheckIn,
                  (v) => toggleNotify('notifyCheckIn', v)),
              _toggleRow('하원 알림', user.notifyCheckOut,
                  (v) => toggleNotify('notifyCheckOut', v)),
            ]),
            const SizedBox(height: AppSpace.md),
            const _SectionLabel('기타'),
            _RowsCard([
              _plainRow('앱 버전', trailingText: '1.0.0'),
              _plainRow('문의하기',
                  trailing: const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textFaint),
                  onTap: () => _snack(context, '준비 중이에요.')),
            ]),
            const SizedBox(height: AppSpace.md),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: GestureDetector(
                  onTap: () => confirmSignOut(context, ref),
                  child: const Text('로그아웃', style: AppText.caption),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cardBorder,
            child: Text(
              user.name.isNotEmpty ? user.name.characters.first : '?',
              style: AppText.cardTitle.copyWith(color: AppColors.textSub),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain)),
                const SizedBox(height: 2),
                Text('학부모 · ${user.email}',
                    style: AppText.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textFaint),
        ],
      ),
    );
  }

  Widget _childRow(String name) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primarySoft,
            child: Text(name.characters.first,
                style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(name, style: AppText.body),
        ],
      ),
    );
  }

  Widget _codeRow(BuildContext context, String code) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        _snack(context, '복사했어요');
      },
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('선생님 코드', style: AppText.body),
            Text(code,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppColors.primaryDeep,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _addChildRow(BuildContext context) {
    return InkWell(
      onTap: () => _snack(context, '준비 중이에요.'),
      child: const SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('아이 추가', style: AppText.body),
            Icon(Icons.add, size: 20, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _plainRow(String label,
      {String? trailingText, Widget? trailing, VoidCallback? onTap}) {
    final Widget tail = trailing ??
        (trailingText != null
            ? Text(trailingText, style: AppText.caption)
            : const SizedBox.shrink());
    final row = SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          tail,
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── 선생님 설정 (기존 유지) ─────────────────────────────────
class _TeacherSettings extends ConsumerWidget {
  final AppUser user;
  const _TeacherSettings({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentCount = ref.watch(teacherStudentsProvider).value?.length ?? 0;
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
                decoration: AppDecoration.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('내 정보', style: AppText.cardTitle),
                    const SizedBox(height: AppSpace.sm),
                    _row('이름', user.name),
                    _row('역할', '선생님'),
                    _row('이메일', user.email),
                    _row('우리 반 학생', '$studentCount명'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              _TeacherCodeCard(code: user.teacherCode ?? '------'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => confirmSignOut(context, ref),
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

/// 선생님 6자리 코드 카드.
class _TeacherCodeCard extends StatelessWidget {
  final String code;
  const _TeacherCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppDecoration.tint(AppColors.primarySoft),
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
