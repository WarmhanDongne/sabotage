import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'dart:math';
/// 방 생성 및 입장을 담당하는 로비 화면.
/// DESIGN.md 기준: 골드/브라스 광산 테마
class LobbyView extends StatefulWidget {
  const LobbyView({super.key});

  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  final _roomCodeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isHost = true;

  @override
  void dispose() {
    _roomCodeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 비네팅(Vignette) 효과 배경
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Color(0xFF1B1B1F),   // surface-container-low (중심)
                  Color(0xFF0D0E11),   // surface-container-lowest (외곽)
                ],
              ),
            ),
          ),
          // 콘텐츠
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildRoleToggle(),
                    const SizedBox(height: 28),
                    if (!_isHost) ...[
                      _buildTextField(
                        controller: _roomCodeController,
                        label: '방 코드 입력',
                        icon: Symbols.meeting_room,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      controller: _nicknameController,
                      label: '닉네임 입력',
                      icon: Symbols.person,
                    ),
                    const SizedBox(height: 36),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 골드 글로우 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SabotageColors.primaryContainer.withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Icon(Symbols.diamond, color: SabotageColors.primaryContainer, size: 56),
        ),
        const SizedBox(height: 20),
        // 제목
        Text(
          'SABOTEUR',
          style: TextStyle(
            color: SabotageColors.primary,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            fontFamily: 'Literata',
            shadows: [
              Shadow(
                color: SabotageColors.primaryContainer.withOpacity(0.35),
                blurRadius: 32,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'UNDER THE SURFACE',
          style: TextStyle(
            color: SabotageColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 3,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: SabotageColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SabotageColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: _roleButton('호스트 (태블릿)', true, Symbols.desktop_mac)),
          Expanded(child: _roleButton('플레이어 (모바일)', false, Symbols.smartphone)),
        ],
      ),
    );
  }

  Widget _roleButton(String label, bool isHostOption, IconData icon) {
    final isSelected = _isHost == isHostOption;
    return GestureDetector(
      onTap: () => setState(() => _isHost = isHostOption),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? SabotageColors.secondaryContainer.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: SabotageColors.secondary.withOpacity(0.4))
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? SabotageColors.primaryContainer : SabotageColors.muted,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? SabotageColors.onSurface : SabotageColors.muted,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: SabotageColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: SabotageColors.muted),
        prefixIcon: Icon(icon, color: SabotageColors.muted, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SabotageColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SabotageColors.primaryContainer, width: 1.5),
        ),
        filled: true,
        fillColor: SabotageColors.surfaceContainerLowest,
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: SabotageColors.goldGlow,
            blurRadius: 32,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SabotageColors.primaryContainer,
          foregroundColor: SabotageColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 0,
        ),
        onPressed: _handleAction,
        child: Text(
          _isHost ? '방 만들기' : '입장하기',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Future<void> _handleAction() async {
    final repo = context.read<GameRepository>();
    final authRepo = context.read<AuthRepository>();
    
    // 익명 로그인으로 고유 UID 획득
    final user = await authRepo.signInAnonymously();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패. 다시 시도해주세요.')),
        );
      }
      return;
    }
    final uid = user.uid;

    if (_isHost) {
      // 4자리 랜덤 방 코드 생성
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      final roomCode = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

      await repo.createLobby(roomCode, uid);
      
      if (mounted) {
        // 호스트 대기실로 이동 (추후 라우팅)
        Navigator.pushNamed(context, '/host_waiting?room=$roomCode');
      }
    } else {
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      final nickname = _nicknameController.text.trim();
      if (roomCode.isEmpty || nickname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('방 코드와 닉네임을 모두 입력해주세요.')),
        );
        return;
      }
      
      try {
        await repo.joinLobby(roomCode, uid, nickname);
        if (mounted) {
          // 플레이어 대기실/플레이어 뷰로 이동
          Navigator.pushNamed(context, '/player?room=$roomCode&id=$uid');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('입장 실패: ${e.toString()}')),
          );
        }
      }
    }
  }
}
