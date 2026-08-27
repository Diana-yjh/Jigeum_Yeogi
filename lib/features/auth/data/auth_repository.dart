import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jigeum_yeogi/models/user_role.dart';

/// 사용자에게 보여줄 메시지를 담은 인증 예외.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

/// 인증 + 온보딩 데이터 처리.
/// - 선생님 회원가입: Auth 생성 → 고유 6자리 코드 발급 → users/teachers 문서 생성
/// - 학부모 회원가입: 코드 검증 → Auth 생성 → users 문서 + students 자가등록
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// 로그인.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// 선생님 회원가입. 성공 시 발급된 6자리 코드를 반환.
  Future<String> signUpTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _createAuthUser(email, password);
    final uid = cred.user!.uid;
    try {
      final code = await _issueUniqueTeacherCode(uid);
      await _db.collection('users').doc(uid).set({
        'role': 'teacher',
        'name': name.trim(),
        'email': email.trim(),
        'teacherCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return code;
    } catch (e) {
      // Firestore 단계 실패 시 방금 만든 Auth 계정을 정리(고아 계정 방지).
      await cred.user?.delete();
      rethrow;
    }
  }

  /// 학부모 회원가입. 코드 검증 후 학생 문서를 자가등록한다.
  Future<void> signUpParent({
    required String name,
    required String email,
    required String password,
    required String teacherCode,
    required String childName,
  }) async {
    final code = teacherCode.trim();
    // 1) 계정을 먼저 생성해 로그인 상태로 만든다.
    //    (teachers/students 접근 규칙이 로그인 사용자를 요구하기 때문)
    final cred = await _createAuthUser(email, password);
    final uid = cred.user!.uid;
    try {
      // 2) 로그인 상태에서 코드 유효성 확인.
      final teacherDoc = await _db.collection('teachers').doc(code).get();
      if (!teacherDoc.exists) {
        throw const AuthFailure('선생님 코드를 찾을 수 없어요. 코드를 다시 확인해주세요.');
      }

      // 3) users + students 자가등록.
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(uid), {
        'role': 'parent',
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final studentRef = _db.collection('students').doc();
      batch.set(studentRef, {
        'name': childName.trim(),
        'teacherCode': code,
        'parentUid': uid,
        'classId': null,
        'scheduledDays': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      await cred.user?.delete();
      rethrow;
    }
  }

  /// 역할별 회원가입 진입점(선택 화면에서 사용).
  Future<void> signUp({
    required Role role,
    required String name,
    required String email,
    required String password,
    String? teacherCode,
    String? childName,
  }) async {
    if (role == Role.teacher) {
      await signUpTeacher(name: name, email: email, password: password);
    } else {
      await signUpParent(
        name: name,
        email: email,
        password: password,
        teacherCode: teacherCode ?? '',
        childName: childName ?? '',
      );
    }
  }

  Future<UserCredential> _createAuthUser(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    }
  }

  /// teachers/{code}를 트랜잭션으로 예약해 고유한 6자리 코드를 발급.
  Future<String> _issueUniqueTeacherCode(String uid) async {
    final rand = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = (rand.nextInt(900000) + 100000).toString(); // 100000~999999
      final ref = _db.collection('teachers').doc(code);
      final reserved = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) return false; // 충돌 → 재시도
        tx.set(ref, {
          'uid': uid,
          'academyName': null,
          'classes': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (reserved) return code;
    }
    throw const AuthFailure('코드 발급에 실패했어요. 잠시 후 다시 시도해주세요.');
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '이미 가입된 이메일이에요.';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않아요.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 해요.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않아요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
  }
}
