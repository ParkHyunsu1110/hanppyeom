import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'auth/auth_screen.dart';
import 'start_selection_screen.dart';

/// 로그인 상태에 따라 인증 화면 또는 시작 선택 화면으로 분기한다.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AppScope.of(context).authService;
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        return StartSelectionScreen(uid: user.uid);
      },
    );
  }
}
