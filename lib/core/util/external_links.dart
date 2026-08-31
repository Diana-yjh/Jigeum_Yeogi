import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 밖으로 나가는 링크 모음. 주소가 바뀌면 여기만 고친다.
abstract class ExternalLinks {
  /// 개인정보처리방침 — GitHub Pages(`docs/privacy/`).
  static final privacyPolicy =
      Uri.parse('https://diana-yjh.github.io/Jigeum_Yeogi/privacy/');

  /// 계정 삭제 안내 — GitHub Pages(`docs/account-deletion/`).
  static final accountDeletion =
      Uri.parse('https://diana-yjh.github.io/Jigeum_Yeogi/account-deletion/');

  /// 문의 메일. 제목을 미리 채워 보낸다.
  static final support = Uri(
    scheme: 'mailto',
    path: 'devyjhong@gmail.com',
    queryParameters: {'subject': '[지금여기] 문의'},
  );
}

/// 외부 브라우저/메일 앱으로 연다. 실패하면 스낵바로 알린다.
Future<void> openExternal(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('링크를 열 수 없어요.')),
    );
  }
}
