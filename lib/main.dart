import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/app.dart';

void main() {
  // Riverpod 전역 상태를 위해 ProviderScope로 감싼다.
  runApp(const ProviderScope(child: JigeumYeogiApp()));
}
