import 'package:flutter/material.dart';

/// 방 생성 및 입장을 담당하는 로비 화면.
/// - 호스트: 방 생성 버튼 → Firestore에 새 방 문서 생성 → /table?room={roomId} 이동
/// - 클라이언트: 방 코드 입력 → 닉네임 입력 → /player?room={roomId}&id={playerId} 이동
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
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildRoleToggle(),
                const SizedBox(height: 28),
                if (!_isHost) ...[
                  _buildTextField(
                    controller: _roomCodeController,
                    label: '방 코드 입력',
                    icon: Icons.meeting_room_outlined,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _nicknameController,
                  label: '닉네임 입력',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 32),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.casino, color: Color(0xFFD4A853), size: 64),
        const SizedBox(height: 16),
        Text(
          'SABOTAGE',
          style: TextStyle(
            color: const Color(0xFFD4A853),
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: const Color(0xFFD4A853).withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '광부와 방해꾼의 전쟁',
          style: TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(child: _roleButton('호스트 (태블릿)', true, Icons.desktop_mac)),
          Expanded(child: _roleButton('플레이어 (모바일)', false, Icons.smartphone)),
        ],
      ),
    );
  }

  Widget _roleButton(String label, bool isHostOption, IconData icon) {
    final isSelected = _isHost == isHostOption;
    return GestureDetector(
      onTap: () => setState(() => _isHost = isHostOption),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D6A4F) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.greenAccent : Colors.white38, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4A853), width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFF161B22),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4A853),
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        onPressed: _handleAction,
        child: Text(
          _isHost ? '방 만들기' : '입장하기',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  void _handleAction() {
    // TODO (Phase 3 Firestore 연동): 방 생성 또는 입장 Firestore 액션 호출 후 Navigator.pushNamed 처리
    if (_isHost) {
      // Firestore에 새 방 문서 생성 → 생성된 roomId로 이동
      // Navigator.pushNamed(context, '/table?room=$newRoomId');
    } else {
      final roomCode = _roomCodeController.text.trim();
      final nickname = _nicknameController.text.trim();
      if (roomCode.isEmpty || nickname.isEmpty) return;
      // Navigator.pushNamed(context, '/player?room=$roomCode&id=$newPlayerId');
    }
  }
}
