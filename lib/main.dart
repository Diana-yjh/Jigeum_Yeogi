import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jigeum_yeogi/app.dart';
import 'package:jigeum_yeogi/firebase_options.dart';

/// 백그라운드/종료 상태에서 메시지 수신 핸들러.
/// notification 페이로드는 시스템이 자동 표시하므로 별도 처리는 없음.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화 (firebase_options.dart는 `flutterfire configure`로 생성).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  runApp(const ProviderScope(child: JigeumYeogiApp()));
}
