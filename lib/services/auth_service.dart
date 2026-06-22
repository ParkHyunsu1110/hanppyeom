import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Firebase Auth 래퍼. 이메일/비밀번호 인증과 `users/{uid}` 문서 동기화를 담당.
///
/// Phase 1은 이메일/비밀번호만 지원한다(소셜 로그인은 후순위).
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// 현재 로그인한 Firebase 사용자(없으면 null).
  User? get currentUser => _auth.currentUser;

  /// 로그인 상태 변화 스트림(앱 진입 라우팅에 사용).
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 회원가입 + `users/{uid}` 문서 생성.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(displayName);

    final appUser = AppUser(
      id: user.uid,
      email: email,
      displayName: displayName,
      photoUrl: user.photoURL,
    );
    await _users.doc(user.uid).set(appUser.toMap());
    return appUser;
  }

  /// 로그인. 누락된 경우 `users/{uid}` 문서를 보강 생성한다.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _ensureUserDoc(cred.user!);
  }

  Future<void> signOut() => _auth.signOut();

  /// `users/{uid}` 문서 조회.
  Future<AppUser?> fetchAppUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  /// 문서가 없으면 Auth 정보로 생성하고, 있으면 그대로 반환한다.
  Future<AppUser> _ensureUserDoc(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return AppUser.fromDoc(snap);

    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
    );
    await ref.set(appUser.toMap());
    return appUser;
  }
}
