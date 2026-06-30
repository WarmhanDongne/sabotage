import 'package:flutter/material.dart';
import '../../main.dart';

/// 잘못된 URL 파라미터나 Firestore 오류 발생 시 표시되는 오류 화면.
/// DESIGN.md 골드/브라스 테마 적용
class ErrorView extends StatelessWidget {
  final String message;

  const ErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: SabotageColors.error, size: 64),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: SabotageColors.onSurface, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SabotageColors.primaryContainer,
                foregroundColor: SabotageColors.onPrimary,
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
