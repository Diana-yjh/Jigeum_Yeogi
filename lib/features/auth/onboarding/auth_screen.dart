import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/theme/app_colors.dart';
import 'package:jigeum_yeogi/core/theme/app_dimens.dart';
import 'package:jigeum_yeogi/core/theme/app_text_styles.dart';
import 'package:jigeum_yeogi/features/auth/data/auth_repository.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

/// 역할별 로그인/회원가입 화면.
/// - 선생님: 이름/이메일/비밀번호 (가입 시 6자리 코드 자동 발급)
/// - 학부모: + 선생님 코드 / 자녀 이름
class AuthScreen extends ConsumerStatefulWidget {
  final Role role;
  const AuthScreen({super.key, required this.role});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _teacherCode = TextEditingController();
  final _childName = TextEditingController();

  bool _isSignUp = true;
  bool _loading = false;

  bool get _isTeacher => widget.role == Role.teacher;
  String get _roleLabel => _isTeacher ? '선생님' : '학부모';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _teacherCode.dispose();
    _childName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (_isSignUp) {
        await repo.signUp(
          role: widget.role,
          name: _name.text,
          email: _email.text,
          password: _password.text,
          teacherCode: _teacherCode.text,
          childName: _childName.text,
        );
      } else {
        await repo.signIn(email: _email.text, password: _password.text);
      }
      // 성공 → 루트(AppRoot)가 로그인 상태를 감지해 탭 셸로 전환.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('문제가 발생했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textMain,
        title: Text('$_roleLabel ${_isSignUp ? '회원가입' : '로그인'}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isSignUp) ...[
                  _field(_name, '이름', hint: '실명을 입력해주세요'),
                  const SizedBox(height: AppSpace.md),
                ],
                _field(
                  _email,
                  '이메일',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? '올바른 이메일을 입력해주세요'
                      : null,
                ),
                const SizedBox(height: AppSpace.md),
                _field(
                  _password,
                  '비밀번호',
                  obscure: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? '비밀번호는 6자 이상이에요'
                      : null,
                ),
                if (_isSignUp && !_isTeacher) ...[
                  const SizedBox(height: AppSpace.md),
                  _field(
                    _teacherCode,
                    '선생님 코드 (6자리)',
                    keyboardType: TextInputType.number,
                    hint: '선생님에게 받은 6자리 코드',
                    validator: (v) => (v == null || v.trim().length != 6)
                        ? '6자리 코드를 입력해주세요'
                        : null,
                  ),
                  const SizedBox(height: AppSpace.md),
                  _field(_childName, '자녀 이름', hint: '학원에 등록된 자녀 이름'),
                ],
                const SizedBox(height: AppSpace.xl),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    shape: const StadiumBorder(),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? '가입하고 시작하기' : '로그인'),
                ),
                const SizedBox(height: AppSpace.md),
                TextButton(
                  onPressed:
                      _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDeep),
                  child: Text(_isSignUp
                      ? '이미 계정이 있어요 · 로그인'
                      : '처음이에요 · 회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: AppSpace.xs),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator ??
              (v) => (v == null || v.trim().isEmpty) ? '$label을(를) 입력해주세요' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.md),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ),
      ],
    );
  }
}
