import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 익명 로그인 수행
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint("Anonymous Sign In Success: ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e) {
      debugPrint("Anonymous Sign In Failed: $e");
      return null;
    }
  }

  // 현재 유저
  User? get currentUser => _auth.currentUser;

  // 유저 상태 스트림 (로그인/로그아웃 상태 감지)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
