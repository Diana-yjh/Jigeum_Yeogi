import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/features/auth/state/auth_providers.dart';

/// FCM 토큰 발급·저장 및 수신 설정.
/// 실제 발송은 Cloud Functions에서만 한다(클라이언트는 수신·토큰만).
class NotificationService {
  NotificationService(this._ref);
  final Ref _ref;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// 로그인 사용자 기준으로 알림 권한 요청 + 토큰 저장 + 갱신 구독.
  /// (iOS 시뮬레이터 등 APNs 미지원 환경에서 실패해도 앱에 지장 없도록 방어)
  Future<void> registerForCurrentUser() async {
    try {
      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _fcm.getToken();
      await _saveToken(token);

      // 토큰 갱신 시 재저장.
      _fcm.onTokenRefresh.listen(_saveToken);
    } catch (_) {
      // 토큰 발급 실패(예: 시뮬레이터 APNs 없음) — 무시.
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final uid = _ref.read(appUserProvider).value?.uid;
    if (uid == null) return;
    await _ref
        .read(authRepositoryProvider)
        .updateUserFields(uid, {'fcmToken': token});
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
