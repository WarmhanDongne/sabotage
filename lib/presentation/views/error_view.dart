import 'package:flutter/material.dart';

/// 잘못된 URL 파라미터나 Firestore 오류 발생 시 표시되는 오류 화면.
class ErrorView extends StatelessWidget {
  final String message;

  const ErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
              icon: const Icon(Icons.home_outlined),
              label: const Text('처음으로'),
            ),
          ],
        ),
      ),
    );
  }
}
