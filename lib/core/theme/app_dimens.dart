import 'package:flutter/material.dart';

/// 간격·모서리·그림자 토큰.
abstract class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract class AppRadius {
  static const sm = 14.0;
  static const card = 24.0; // 큰 라운드(소프트)
  static const chip = 18.0;
  static const pill = 999.0;
}

/// 부드러운 웜톤 그림자 — 하드 테두리 대신 사용.
abstract class AppShadow {
  static const soft = [
    BoxShadow(
      color: Color(0x14453121), // 웜톤 8%
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
}
