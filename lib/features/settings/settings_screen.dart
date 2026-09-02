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

    // 연결된 선생님 {코드: 닉네임}. 저장된 맵 + (구버전 호환) 계정 코드·자녀 코드 병합.
    final teachers = <String, String>{...user.teachers};
    final legacyCodes = [
      if (user.teacherCode != null) user.teacherCode!,
      ...children.map((c) => c.teacherCode),
    ];
    for (final c in legacyCodes) {
      teachers.putIfAbsent(c, () => '선생님');
    }

    // 우리 아이 섹션 행: 자녀 이름(+선생님 닉네임, 수정·삭제) → 아이 추가.
    final childRows = <Widget>[];
    if (children.isEmpty) {
      childRows.add(_childRow('연결된 자녀 없음'));
    } else {
      for (final c in children) {
        childRows.add(_childRow(
          c.name,
          // 선생님이 여럿일 때만 누구 반인지 표시.
          caption: teachers.length >= 2 ? teachers[c.teacherCode] : null,
          onEdit: () => showDialog(
            context: context,
            builder: (_) => EditNameDialog(
              title: '아이 이름 수정',
              label: '자녀 이름',
              initial: c.name,
              onSubmit: (name) =>
                  ref.read(authRepositoryProvider).renameChild(c.id, name),
            ),
          ),
          onDelete: () => _confirmDeleteChild(context, ref, c),
        ));
      }
    }
    childRows.add(_addChildRow(context, ref, user.uid, teachers));

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
            _RowsCard(_teacherRows(context, ref, user.uid, teachers, children)),
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
  List<Widget> _teacherRows(BuildContext context, WidgetRef ref, String uid,
      Map<String, String> teachers, List<Student> children) {
    final rows = <Widget>[];
    for (final e in teachers.entries) {
      final code = e.key;
      final hasChildren = children.any((c) => c.teacherCode == code);
      rows.add(SizedBox(
        height: 44,
        child: Row(
          children: [
            const Icon(Icons.school_outlined,
                size: 20, color: AppColors.primaryDeep),
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
              onTap: () =>
                  _confirmRemoveTeacher(context, ref, uid, code, hasChildren),
              child: const Icon(Icons.link_off,
                  size: 20, color: AppColors.textFaint),
            ),
          ],
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
      String uid, String code, bool hasChildren) async {
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
      await ref.read(authRepositoryProvider).removeTeacher(uid, code);
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


  Widget _addChildRow(BuildContext context, WidgetRef ref, String uid,
      Map<String, String> teachers) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _AddChildDialog(uid: uid, teachers: teachers),
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
/// 아이 추가 다이얼로그 — 자녀 이름 + (선생님 여럿이면) 선생님 선택.
class _AddChildDialog extends ConsumerStatefulWidget {
  final String uid;
  final Map<String, String> teachers; // {코드: 닉네임}
  const _AddChildDialog({required this.uid, required this.teachers});

  @override
  ConsumerState<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends ConsumerState<_AddChildDialog> {
  final _name = TextEditingController();
  String? _code; // 선택된 선생님 코드
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = widget.teachers.keys.isNotEmpty ? widget.teachers.keys.first : null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 선생님이 하나면 캡션으로, 여럿이면 드롭다운으로.
          if (widget.teachers.length == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Text(
                '${widget.teachers.values.first} · 코드 ${widget.teachers.keys.first}',
                style: AppText.caption,
              ),
            )
          else if (widget.teachers.length >= 2)
            DropdownButtonFormField<String>(
              initialValue: _code,
              decoration: const InputDecoration(labelText: '선생님'),
              items: [
                for (final e in widget.teachers.entries)
                  DropdownMenuItem(
                      value: e.key, child: Text('${e.value} (${e.key})')),
              ],
              onChanged: (v) => setState(() => _code = v),
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
