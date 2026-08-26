import 'package:flutter/material.dart';

/// 앱 색상 토큰 — 하드코딩 금지, 반드시 이 상수를 사용할 것.
/// 값은 디자인 스펙(목업 톤)을 그대로 따른다.
abstract class AppColors {
  static const background = Color(0xFFFAF7F2); // 웜 화이트/베이지
  static const primary = Color(0xFFD97757); // 클레이 오렌지
  static const primarySoft = Color(0xFFF2E3DA); // 연한 오렌지 (등원 표시, 뱃지 배경)
  static const primaryDeep = Color(0xFFB54E2C); // 아이콘, 강조 텍스트

  static const textMain = Color(0xFF35302A);
  static const textSub = Color(0xFF8C8577);
  static const textFaint = Color(0xFF9B9384);

  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE5DED2); // 카드 헤어라인
  static const chipNeutral = Color(0xFFEFE9DE);
}
