import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/data/auth_repository.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/student.dart';
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

/// 회원탈퇴 확인 → Auth 계정 삭제(Firestore 데이터는 Cloud Functions 정리).
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('회원탈퇴'),
      content: const Text(
          '계정과 모든 데이터가 삭제되며 되돌릴 수 없어요.\n정말 탈퇴할까요?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('탈퇴'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(authRepositoryProvider).deleteAccount();
  } on AuthFailure catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('탈퇴 중 문제가 발생했어요.')));
    }
  }
}

/// 하단 계정 액션 — 로그아웃 | 회원탈퇴.
Widget accountActionsRow(BuildContext context, WidgetRef ref) {
  return Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => confirmSignOut(context, ref),
          child: const Text('로그아웃', style: AppText.caption),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
          child: Text('|',
              style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
        ),
        GestureDetector(
          onTap: () => confirmDeleteAccount(context, ref),
          child: Text('회원탈퇴',
              style: AppText.caption.copyWith(color: AppColors.danger)),
        ),
      ],
    ),
  );
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
    final children = ref.watch(childrenProvider).value ?? const [];

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

    // 학부모의 선생님 코드(계정에 저장, 없으면 자녀 코드로 폴백).
    final code = user.teacherCode ??
        (children.isNotEmpty ? children.first.teacherCode : null);
    final childIds = children.map((c) => c.id).toList();

    // 우리 아이 섹션 행: 자녀 이름(+삭제) → 아이 추가.
    final childRows = <Widget>[];
    if (children.isEmpty) {
      childRows.add(_childRow('연결된 자녀 없음'));
    } else {
      for (final c in children) {
        childRows.add(_childRow(c.name,
            onDelete: () => _confirmDeleteChild(context, ref, c)));
      }
    }
    childRows.add(_addChildRow(context, ref, user.uid, code));

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
            const SizedBox(height: AppSpace.sm),
            _codeCard(context, ref, user.uid, code, childIds),
            const SizedBox(height: AppSpace.md),
            const _SectionLabel('우리 아이'),
            _RowsCard(childRows),
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
            const SizedBox(height: AppSpace.lg),
            accountActionsRow(context, ref),
            const SizedBox(height: AppSpace.md),
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

  /// 선생님 코드 카드 — 항상 표시, 탭하면 복사, 연필로 수정.
  Widget _codeCard(BuildContext context, WidgetRef ref, String uid,
      String? code, List<String> childIds) {
    final display = code ?? '------';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: AppDecoration.card(),
      child: Row(
        children: [
          const Text('선생님 코드', style: AppText.body),
          const Spacer(),
          GestureDetector(
            onTap: code == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    _snack(context, '복사했어요');
                  },
            child: Text(display,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppColors.primaryDeep,
                    letterSpacing: 2)),
          ),
          const SizedBox(width: AppSpace.sm),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) =>
                  _ChangeCodeDialog(uid: uid, childIds: childIds),
            ),
            child: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }

  Widget _childRow(String name, {VoidCallback? onDelete}) {
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
          Expanded(child: Text(name, style: AppText.body)),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.textFaint),
            ),
        ],
      ),
    );
  }


  Widget _addChildRow(
      BuildContext context, WidgetRef ref, String uid, String? autoCode) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _AddChildDialog(uid: uid, teacherCode: autoCode),
      ),
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

  /// 자녀 삭제 확인.
  Future<void> _confirmDeleteChild(
      BuildContext context, WidgetRef ref, Student child) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('아이 삭제'),
        content: Text('${child.name} 학생을 삭제할까요?\n출결 기록도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteChild(child.id);
    } catch (_) {
      if (context.mounted) _snack(context, '삭제 중 문제가 발생했어요.');
    }
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
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
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
            const SizedBox(height: AppSpace.lg),
            accountActionsRow(context, ref),
            const SizedBox(height: AppSpace.md),
          ],
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

/// 선생님 코드 변경 다이얼로그 — 변경 시 등록된 학생이 모두 삭제됨.
class _ChangeCodeDialog extends ConsumerStatefulWidget {
  final String uid;
  final List<String> childIds;
  const _ChangeCodeDialog({required this.uid, required this.childIds});

  @override
  ConsumerState<_ChangeCodeDialog> createState() => _ChangeCodeDialogState();
}

class _ChangeCodeDialogState extends ConsumerState<_ChangeCodeDialog> {
  final _code = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('6자리 코드를 입력해주세요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).changeParentTeacherCode(
            uid: widget.uid,
            newCode: _code.text,
            childIds: widget.childIds,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('선생님 코드를 변경했어요. 아이를 다시 추가해주세요.')));
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('변경 중 문제가 발생했어요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('선생님 코드 변경'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('코드를 바꾸면 등록된 학생이 모두 삭제됩니다.',
              style: TextStyle(color: AppColors.danger)),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: '새 선생님 코드 (6자리)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('변경'),
        ),
      ],
    );
  }
}

/// 아이 추가 다이얼로그 — 자녀 이름만(선생님 코드는 기존 자녀 코드 자동 사용).
class _AddChildDialog extends ConsumerStatefulWidget {
  final String uid;
  final String? teacherCode; // 자동 입력될 선생님 코드
  const _AddChildDialog({required this.uid, this.teacherCode});

  @override
  ConsumerState<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends ConsumerState<_AddChildDialog> {
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = widget.teacherCode;
    if (code == null || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결된 선생님 코드를 찾을 수 없어요.')));
      return;
    }
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자녀 이름을 입력해주세요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).addChild(
            parentUid: widget.uid,
            teacherCode: code,
            childName: _name.text,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('아이를 추가했어요.')));
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('추가 중 문제가 발생했어요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('아이 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.teacherCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('선생님 코드 ${widget.teacherCode}',
                    style: AppText.caption),
              ),
            ),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '자녀 이름'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
          child: const Text('추가'),
        ),
      ],
    );
  }
}
