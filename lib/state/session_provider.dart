import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

/// 현재 세션의 역할 상태.
///
/// Phase 1: 시작 화면에서 선택한 역할을 담는 임시 상태.
/// null = 아직 역할 미선택(시작 화면 노출).
/// Phase 2에서 Firebase Auth 로그인 결과로 이 값을 채우도록 확장 예정.
class SessionNotifier extends Notifier<Role?> {
  @override
  Role? build() => null;

  /// 역할 선택(로그인 대용).
  void selectRole(Role role) => state = role;

  /// 역할 해제(로그아웃 대용) → 시작 화면으로 복귀.
  void clear() => state = null;
}

final currentRoleProvider =
    NotifierProvider<SessionNotifier, Role?>(SessionNotifier.new);
