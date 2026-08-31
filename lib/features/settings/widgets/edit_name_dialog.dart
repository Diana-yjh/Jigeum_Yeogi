import 'package:flutter/material.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/features/auth/data/auth_repository.dart';

/// 이름 한 줄을 고치는 공용 다이얼로그.
/// 학부모 본인 이름·자녀 이름·선생님 본인 이름 수정에 함께 쓴다.
class EditNameDialog extends StatefulWidget {
  const EditNameDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initial,
    required this.onSubmit,
  });

  /// 다이얼로그 제목. 예: '이름 수정'
  final String title;

  /// 입력란 라벨. 예: '자녀 이름'
  final String label;

  /// 처음 채워둘 값.
  final String initial;

  /// 저장 동작. 실패하면 예외를 던지면 된다.
  final Future<void> Function(String name) onSubmit;

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('이름을 입력해주세요.');
      return;
    }
    if (name == widget.initial.trim()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSubmit(name);
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack('수정했어요.');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('수정 중 문제가 발생했어요.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _saving ? null : _submit(),
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
