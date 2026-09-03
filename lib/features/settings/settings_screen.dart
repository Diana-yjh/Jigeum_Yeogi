import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_decorations.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/core/util/external_links.dart';
import 'package:jigeum_yeogi/features/attendance/state/attendance_providers.dart';
import 'package:jigeum_yeogi/features/auth/data/auth_repository.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/features/settings/widgets/edit_name_dialog.dart';
import 'package:jigeum_yeogi/models/app_user.dart';
import 'package:jigeum_yeogi/models/student.dart';
import 'package:jigeum_yeogi/models/user_role.dart';
import 'package:jigeum_yeogi/shared/widgets/app_background.dart';

/// 설정 화면 — 역할별 분기(학부모/선생님).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    if (user == null) {
      return const AppScaffold();
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
/// 학부모·선생님 공통 '기타' 섹션 행들 — 앱 버전, 개인정보처리방침, 문의.
List<Widget> miscRows(BuildContext context) {
  Widget row(String label, {String? value, Uri? link, IconData? icon}) {
    final tail = value != null
        ? Text(value, style: AppText.caption)
        : Icon(icon ?? Icons.chevron_right,
            size: 20, color: AppColors.textFaint);
    final body = SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: AppText.body), tail],
      ),
    );
    if (link == null) return body;
    return InkWell(onTap: () => openExternal(context, link), child: body);
  }

  return [
    row('앱 버전', value: '1.0.0'),
    row('개인정보처리방침',
        link: ExternalLinks.privacyPolicy, icon: Icons.open_in_new),
    row('문의하기', link: ExternalLinks.support, icon: Icons.mail_outline),
  ];
}

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

    // 연결된 선생님 {코드: 닉네임} — 저장 맵 + 구버전 필드·자녀 코드 병합(모델 헬퍼).
    final teachers =
        user.teacherDirectory(children.map((c) => c.teacherCode));

    // 우리 아이 = 같은 이름은 한 번만. 이름 수정·삭제는 모든 반에 일괄 적용.
    final uniqueNames = <String>[];
    for (final c in children) {
      final n = c.name.trim();
      if (!uniqueNames.contains(n)) uniqueNames.add(n);
    }
    final childRows = <Widget>[];
    if (uniqueNames.isEmpty) {
      childRows.add(_childRow('연결된 자녀 없음'));
    } else {
      for (final name in uniqueNames) {
        final enrolled = children
            .where((c) => c.name.trim() == name && c.teacherCode.isNotEmpty)
            .map((c) => teachers[c.teacherCode] ?? '선생님')
            .toList();
        childRows.add(_childRow(
          name,
          caption: enrolled.isEmpty ? '연결된 선생님 없음' : enrolled.join(' · '),
          onEdit: () => showDialog(
            context: context,
            builder: (_) => EditNameDialog(
              title: '아이 이름 수정',
              label: '자녀 이름',
              initial: name,
              onSubmit: (newName) =>
                  ref.read(authRepositoryProvider).renameChildEverywhere(
                        parentUid: user.uid,
                        oldName: name,
                        newName: newName,
                      ),
            ),
          ),
          onDelete: () =>
              _confirmDeleteEverywhere(context, ref, user.uid, name),
        ));
      }
    }

    return AppScaffold(
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
            _profileCard(context, ref, user),
            const SizedBox(height: AppSpace.md),
            const _SectionLabel('선생님'),
            _RowsCard(_teacherRows(
                context, ref, user, teachers, children)),
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
            _RowsCard(miscRows(context)),
            const SizedBox(height: AppSpace.lg),
            accountActionsRow(context, ref),
            const SizedBox(height: AppSpace.md),
          ],
        ),
      ),
    );
  }

  /// 프로필 카드 — 탭하면 내 이름 수정.
  Widget _profileCard(BuildContext context, WidgetRef ref, AppUser user) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => showDialog(
        context: context,
        builder: (_) => EditNameDialog(
          title: '내 이름 수정',
          label: '이름',
          initial: user.name,
          onSubmit: (name) => ref
              .read(authRepositoryProvider)
              .updateUserFields(user.uid, {'name': name}),
        ),
      ),
      child: Container(
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
      ),
    );
  }

  /// 선생님 섹션 행들 — 연결된 선생님(닉네임·코드·수정·해제) + 선생님 추가.
  List<Widget> _teacherRows(BuildContext context, WidgetRef ref, AppUser user,
      Map<String, String> teachers, List<Student> children) {
    final uid = user.uid;
    final rows = <Widget>[];
    final codes = teachers.keys.toList();
    for (final e in teachers.entries) {
      final code = e.key;
      final hasChildren = children.any((c) => c.teacherCode == code);
      final color = AppColors.teacherColor(
          stored: user.teacherColors[code], index: codes.indexOf(code));
      rows.add(SizedBox(
        height: 44,
        child: Row(
          children: [
            // 구분색 도트 — 탭하면 색 선택.
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => _TeacherColorDialog(
                    uid: uid, code: code, current: color),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(e.value,
                  style: AppText.body, overflow: TextOverflow.ellipsis),
            ),
            // 코드 — 탭하면 복사.
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                _snack(context, '복사했어요');
              },
              child: Text(code,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: AppColors.primaryDeep,
                      letterSpacing: 2)),
            ),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => EditNameDialog(
                  title: '선생님 닉네임',
                  label: '닉네임 (예: 수학 김선생님)',
                  initial: e.value,
                  onSubmit: (nick) => ref
                      .read(authRepositoryProvider)
                      .renameTeacher(uid, code, nick),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textFaint),
              ),
            ),
            GestureDetector(
              onTap: () => _confirmRemoveTeacher(context, ref, uid, code,
                  hasChildren: hasChildren,
                  clearLegacy: user.teacherCode == code),
              child: const Icon(Icons.link_off,
                  size: 20, color: AppColors.textFaint),
            ),
          ],
        ),
      ));
      // 이 반에 속한 아이들 — 반에서 빼기(x)와 반별 아이 추가.
      final inClass =
          children.where((c) => c.teacherCode == code).toList();
      for (final c in inClass) {
        rows.add(SizedBox(
          height: 38,
          child: Row(
            children: [
              const SizedBox(width: AppSpace.lg),
              Icon(Icons.subdirectory_arrow_right,
                  size: 16, color: AppColors.textFaint),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(c.name,
                    style: AppText.caption
                        .copyWith(color: AppColors.textMain)),
              ),
              GestureDetector(
                onTap: () => _confirmRemoveFromClass(context, ref, c, e.value,
                    // 다른 반 수강이 없으면 삭제 대신 연결 해제(아이 보존).
                    lastEnrollment: !children.any((x) =>
                        x.id != c.id &&
                        x.name.trim() == c.name.trim() &&
                        x.teacherCode.isNotEmpty)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  child: Icon(Icons.close,
                      size: 18, color: AppColors.textFaint),
                ),
              ),
            ],
          ),
        ));
      }
      rows.add(InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => _AddChildToClassDialog(
            uid: uid,
            code: code,
            teacherLabel: e.value,
            existingNames: {
              for (final c in children)
                if (!children
                    .where((x) => x.teacherCode == code)
                    .any((x) => x.name.trim() == c.name.trim()))
                  c.name.trim(),
            }.toList(),
            namesInClass:
                inClass.map((c) => c.name.trim()).toSet().toList(),
            // 연결 해제된 수강(빈 코드) — 재연결에 재사용해 기록을 잇는다.
            ghostIdByName: {
              for (final c in children)
                if (c.teacherCode.isEmpty) c.name.trim(): c.id,
            },
          ),
        ),
        child: const SizedBox(
          height: 38,
          child: Row(
            children: [
              SizedBox(width: AppSpace.lg),
              Icon(Icons.person_add_alt, size: 16, color: AppColors.textFaint),
              SizedBox(width: AppSpace.sm),
              Text('이 반에 아이 추가', style: AppText.caption),
            ],
          ),
        ),
      ));
    }
    rows.add(InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _AddTeacherDialog(uid: uid),
      ),
      child: const SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('선생님 추가', style: AppText.body),
            Icon(Icons.add, size: 20, color: AppColors.textFaint),
          ],
        ),
      ),
    ));
    return rows;
  }

  /// 선생님 연결 해제 확인 — 그 반 자녀가 남아 있으면 막는다.
  Future<void> _confirmRemoveTeacher(BuildContext context, WidgetRef ref,
      String uid, String code,
      {required bool hasChildren, required bool clearLegacy}) async {
    if (hasChildren) {
      _snack(context, '이 선생님 반에 아이가 있어요. 아이를 먼저 삭제하거나 옮겨주세요.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선생님 연결 해제'),
        content: Text('코드 $code 선생님과의 연결을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .removeTeacher(uid, code, clearLegacy: clearLegacy);
    } catch (_) {
      if (context.mounted) _snack(context, '해제 중 문제가 발생했어요.');
    }
  }

  Widget _childRow(String name,
      {String? caption, VoidCallback? onEdit, VoidCallback? onDelete}) {
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
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child:
                      Text(name, style: AppText.body, overflow: TextOverflow.ellipsis),
                ),
                if (caption != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(caption,
                        style: AppText.caption, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textFaint),
              ),
            ),
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



  /// 반에서 빼기.
  /// 다른 반에도 있는 아이는 이 수강만 삭제하고, 유일한 반이면 삭제 대신
  /// 연결 해제(teacherCode 비움) — 아이와 지난 기록이 학부모 앱에 남는다.
  Future<void> _confirmRemoveFromClass(BuildContext context, WidgetRef ref,
      Student child, String teacherLabel,
      {required bool lastEnrollment}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${child.name} · $teacherLabel'),
        content: Text(lastEnrollment
            ? '이 반에서 아이를 뺄까요?\n아이와 지난 기록은 우리 아이 목록에 남아요.'
            : '이 반에서 아이를 뺄까요?\n이 반의 출결 기록도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('빼기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (lastEnrollment) {
        await ref.read(authRepositoryProvider).unlinkStudent(child.id);
      } else {
        await ref.read(authRepositoryProvider).deleteChild(child.id);
      }
    } catch (_) {
      if (context.mounted) _snack(context, '삭제 중 문제가 발생했어요.');
    }
  }

  /// 아이를 모든 반에서 삭제.
  Future<void> _confirmDeleteEverywhere(
      BuildContext context, WidgetRef ref, String uid, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name 삭제'),
        content: const Text('아이를 모든 선생님 반에서 삭제할까요?\n'
            '출결 기록도 함께 삭제되며 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .deleteChildEverywhere(parentUid: uid, name: name);
      if (context.mounted) _snack(context, '$name 아이를 삭제했어요.');
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
    return AppScaffold(
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
                  _row(
                    '이름',
                    user.name,
                    onEdit: () => showDialog(
                      context: context,
                      builder: (_) => EditNameDialog(
                        title: '내 이름 수정',
                        label: '이름',
                        initial: user.name,
                        onSubmit: (name) => ref
                            .read(authRepositoryProvider)
                            .updateUserFields(user.uid, {'name': name}),
                      ),
                    ),
                  ),
                  _row('역할', '선생님'),
                  _row('이메일', user.email),
                  _row('우리 반 학생', '$studentCount명'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _TeacherCodeCard(code: user.teacherCode ?? '------'),
            const SizedBox(height: AppSpace.md),
            const _SectionLabel('기타'),
            _RowsCard(miscRows(context)),
            const SizedBox(height: AppSpace.lg),
            accountActionsRow(context, ref),
            const SizedBox(height: AppSpace.md),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {VoidCallback? onEdit}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(width: AppSpace.md),
          // 값은 남는 폭 안에서 오른쪽 정렬 — 긴 이메일·큰 글씨에서 넘치지 않게.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(value,
                      style: AppText.body,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textFaint),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (onEdit == null) return row;
    return InkWell(onTap: onEdit, child: row);
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
/// 반별 아이 추가 — 기존 아이는 선택으로(같은 아이는 한 번만 입력),
/// 새 아이는 직접 입력.
class _AddChildToClassDialog extends ConsumerStatefulWidget {
  final String uid;
  final String code;
  final String teacherLabel;
  final List<String> existingNames; // 이 반에 아직 없는 기존 아이들
  final List<String> namesInClass; // 이 반에 이미 있는 이름(중복 방지)
  final Map<String, String> ghostIdByName; // 연결 해제된 수강 {이름: 문서 id}
  const _AddChildToClassDialog({
    required this.uid,
    required this.code,
    required this.teacherLabel,
    required this.existingNames,
    required this.namesInClass,
    this.ghostIdByName = const {},
  });

  @override
  ConsumerState<_AddChildToClassDialog> createState() =>
      _AddChildToClassDialogState();
}

class _AddChildToClassDialogState
    extends ConsumerState<_AddChildToClassDialog> {
  static const _newChild = '__new__';
  final _name = TextEditingController();
  late String _selected =
      widget.existingNames.isNotEmpty ? widget.existingNames.first : _newChild;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name =
        (_selected == _newChild ? _name.text : _selected).trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자녀 이름을 입력해주세요.')));
      return;
    }
    if (widget.namesInClass.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 이 반에 있는 아이예요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final ghostId = widget.ghostIdByName[name];
      if (ghostId != null) {
        // 해제됐던 수강을 이 반으로 재연결 — 지난 기록 유지.
        await ref.read(authRepositoryProvider).relinkStudent(ghostId, widget.code);
      } else {
        await ref.read(authRepositoryProvider).addChild(
              parentUid: widget.uid,
              teacherCode: widget.code,
              childName: name,
            );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$name 아이를 ${widget.teacherLabel} 반에 추가했어요.')));
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
      title: Text('${widget.teacherLabel} 반에 아이 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.existingNames.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _selected,
              decoration: const InputDecoration(labelText: '아이'),
              items: [
                for (final n in widget.existingNames)
                  DropdownMenuItem(value: n, child: Text(n)),
                const DropdownMenuItem(
                    value: _newChild, child: Text('새로운 아이 직접 입력…')),
              ],
              onChanged: (v) => setState(() => _selected = v ?? _newChild),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          if (_selected == _newChild)
            TextField(
              controller: _name,
              autofocus: widget.existingNames.isEmpty,
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

/// 선생님 추가 다이얼로그 — 6자리 코드 + 닉네임.
class _AddTeacherDialog extends ConsumerStatefulWidget {
  final String uid;
  const _AddTeacherDialog({required this.uid});

  @override
  ConsumerState<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends ConsumerState<_AddTeacherDialog> {
  final _code = TextEditingController();
  final _nickname = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _nickname.dispose();
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
      await ref.read(authRepositoryProvider).addTeacher(
            uid: widget.uid,
            code: _code.text,
            nickname: _nickname.text,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('선생님을 추가했어요.')));
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
      title: const Text('선생님 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            autofocus: true,
            maxLength: 6,
            decoration: const InputDecoration(labelText: '선생님 코드 (6자리)'),
          ),
          TextField(
            controller: _nickname,
            maxLength: 20,
            onSubmitted: (_) => _saving ? null : _submit(),
            decoration: const InputDecoration(
                labelText: '닉네임 (예: 수학 김선생님)', helperText: '비우면 "선생님"'),
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

/// 선생님 구분색 선택 — 프리셋 팔레트에서 하나.
class _TeacherColorDialog extends ConsumerWidget {
  final String uid;
  final String code;
  final Color current;
  const _TeacherColorDialog(
      {required this.uid, required this.code, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('구분색 선택'),
      content: Wrap(
        spacing: AppSpace.md,
        runSpacing: AppSpace.md,
        children: [
          for (final c in AppColors.teacherPalette)
            GestureDetector(
              onTap: () async {
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .setTeacherColor(uid, code, c.toARGB32());
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('저장 중 문제가 발생했어요.')));
                  }
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.toARGB32() == current.toARGB32()
                        ? AppColors.textMain
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: c.toARGB32() == current.toARGB32()
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
