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

  /// 사용자 문서 부분 업데이트(알림 설정 등).
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) {
    return _db.collection('users').doc(uid).set(fields, SetOptions(merge: true));
  }

  /// 로그인한 학부모가 자녀를 추가(코드 검증 후 students 생성).
  Future<void> addChild({
    required String parentUid,
    required String teacherCode,
    required String childName,
  }) async {
    final code = teacherCode.trim();
    final teacherDoc = await _db.collection('teachers').doc(code).get();
    if (!teacherDoc.exists) {
      throw const AuthFailure('선생님 코드를 찾을 수 없어요. 코드를 다시 확인해주세요.');
    }
    await _db.collection('students').add({
      'name': childName.trim(),
      'teacherCode': code,
      'parentUid': parentUid,
      'classId': null,
      'schedule': <String, dynamic>{},
      'scheduledDays': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 자녀(학생) 이름 수정.
  Future<void> renameChild(String studentId, String name) {
    return _db
        .collection('students')
        .doc(studentId)
        .set({'name': name.trim()}, SetOptions(merge: true));
  }

  /// 선생님이 학생을 반에서 내보내기 — 학생 문서는 남기고 연결만 해제.
  /// 학부모 앱에는 아이와 지난 출결 기록이 그대로 남는다.
  Future<void> unlinkStudent(String studentId) {
    return _db
        .collection('students')
        .doc(studentId)
        .update({'teacherCode': ''});
  }

  /// 학생 삭제 — 학부모(내 자녀)·선생님(내 반 학생) 공용.
  /// 출결 기록은 Cloud Functions(onStudentDelete)가 정리.
  Future<void> deleteChild(String studentId) {
    return _db.collection('students').doc(studentId).delete();
  }

  /// 학부모가 선생님을 추가로 연결. 코드 검증 후 닉네임과 함께 저장.
  Future<void> addTeacher({
    required String uid,
    required String code,
    required String nickname,
  }) async {
    final trimmed = code.trim();
    final teacherDoc = await _db.collection('teachers').doc(trimmed).get();
    if (!teacherDoc.exists) {
      throw const AuthFailure('선생님 코드를 찾을 수 없어요. 코드를 다시 확인해주세요.');
    }
    await _db.collection('users').doc(uid).set({
      'teachers': {
        trimmed: nickname.trim().isEmpty ? '선생님' : nickname.trim(),
      },
    }, SetOptions(merge: true));
  }

  /// 연결된 선생님의 닉네임 변경.
  Future<void> renameTeacher(String uid, String code, String nickname) {
    return _db.collection('users').doc(uid).set({
      'teachers': {code: nickname.trim()},
    }, SetOptions(merge: true));
  }

  /// 선생님 연결 해제. 그 선생님 소속 자녀가 있으면 화면에서 먼저 막는다.
  Future<void> removeTeacher(String uid, String code) {
    return _db
        .collection('users')
        .doc(uid)
        .update({'teachers.$code': FieldValue.delete()});
  }

  /// 회원탈퇴 — Auth 계정 삭제. Firestore 데이터는 Cloud Functions가 정리.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthFailure('보안을 위해 다시 로그인한 뒤 탈퇴해주세요.');
      }
      throw AuthFailure(_authMessage(e));
    }
  }

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
        'teacherCode': code, // 첫 선생님 코드(구버전 호환)
        'teachers': {code: '선생님'}, // 연결된 선생님 {코드: 닉네임}
        'createdAt': FieldValue.serverTimestamp(),
      });
      final studentRef = _db.collection('students').doc();
      batch.set(studentRef, {
        'name': childName.trim(),
        'teacherCode': code,
        'parentUid': uid,
        'classId': null,
        'schedule': <String, String>{},
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
