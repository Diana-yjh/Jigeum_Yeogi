import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jigeum_yeogi/core/firebase/firebase_providers.dart';
import 'package:jigeum_yeogi/features/auth/data/auth_repository.dart';
import 'package:jigeum_yeogi/models/app_user.dart';

/// 인증 리포지토리 provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// Firebase 로그인 상태 스트림(로그인/로그아웃 감지).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// 현재 로그인한 사용자의 Firestore 프로필(users/{uid}) 스트림.
/// 로그아웃 상태이거나 아직 문서가 없으면 null.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(null);
  }
  final db = ref.watch(firestoreProvider);
  return db.collection('users').doc(authUser.uid).snapshots().map(
        (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
      );
});
