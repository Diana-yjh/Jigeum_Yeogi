import 'package:flutter/material.dart';

/// 앱 색상 토큰 — 하드코딩 금지, 반드시 이 상수를 사용할 것.
/// 톤: 소프트 파스텔 + 웜 뉴트럴. 브랜드는 클레이 오렌지(코랄) 계열 유지.
abstract class AppColors {
  static const background = Color(0xFFFBF8F3); // 웜 화이트/베이지 (더 밝고 깨끗)
  static const primary = Color(0xFFDD8064); // 소프트 코랄 오렌지
  static const primarySoft = Color(0xFFFBEADF); // 연한 피치 — 칩·뱃지·아바타 배경
  static const primaryTint = Color(0xFFF6D9CB); // 조금 더 진한 피치 틴트
  static const primaryDeep = Color(0xFFB15633); // 딥 테라코타 — 아이콘·강조 텍스트

  // 어시 파스텔 보조색(세이지) — 긍정/정규 상태에 소량 사용.
  static const sageSoft = Color(0xFFE7EDE4);
  static const sageDeep = Color(0xFF5E7D57);

  static const textMain = Color(0xFF2C2722);
  static const textSub = Color(0xFF8B8378);
  static const textFaint = Color(0xFFB5ADA1);

  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEFE9DF); // 매우 옅은 헤어라인
  static const chipNeutral = Color(0xFFF1ECE3);

  static const danger = Color(0xFFC85C4E); // 파괴적 액션(회원탈퇴 등)

  // 자녀 구분색 — 다자녀 달력에서 아이마다 하나씩. 채도를 낮춘 더스티 톤으로
  // 코랄 primary와 나란히 놓여도 튀지 않게 맞췄다.
  static const skyDeep = Color(0xFF6B8CB5); // 더스티 블루
  static const plumDeep = Color(0xFF9A7BAA); // 더스티 플럼

  /// 자녀 순서대로 배정하는 색. 넘치면 처음부터 다시 돈다.
  static const childPalette = [primary, sageDeep, skyDeep, plumDeep];
  static Color childColor(int index) =>
      childPalette[index % childPalette.length];

  /// 히어로 카드용 코랄 그라디언트.
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE28E70), Color(0xFFD57352)],
  );
}
