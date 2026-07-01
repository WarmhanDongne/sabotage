import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/card.dart' as game_card;
import '../../logic/card_image_mapper.dart';

/// 보드판 위에 단일 카드 한 장을 렌더링하는 위젯.
/// 오리지널 에셋(board_info) 이미지를 로드하여 표시하며, 탭 애니메이션(움찔) 및 텍스트 1초 노출을 처리합니다.
class CardWidget extends StatefulWidget {
  final game_card.Card? card;
  final bool isRevealed;
  final double? width;
  final double? height;

  const CardWidget({
    super.key,
    required this.card,
    this.isRevealed = true,
    this.width,
    this.height,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  
  String? _overlayText;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // 클릭 시 작아졌다가(0.9) 원래 크기(1.0)로 돌아오는 탄성 애니메이션
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _overlayTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (widget.card == null) return;

    // 1. 움찔 애니메이션 재생
    _bounceController.forward(from: 0.0);

    // 2. 텍스트 결정 로직
    String? textToShow;
    if (widget.card!.type == game_card.CardType.start) {
      textToShow = "시작 위치";
    } else if (widget.card!.type == game_card.CardType.goal) {
      textToShow = "도착 위치";
    }

    if (textToShow != null) {
      setState(() {
        _overlayText = textToShow;
      });

      // 3. 1초 뒤 텍스트 제거
      _overlayTimer?.cancel();
      _overlayTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _overlayText = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.card == null) {
      // 빈 격자: 완전 투명 (배경 이미지에 이미 그려져 있음)
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildCardImage(),
                  if (_overlayText != null) _buildTextOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardImage() {
    String assetPath = 'assets/board_info/004_path/004_path_back.png';
    if (widget.card != null) {
      assetPath = CardImageMapper.getImagePath(widget.card!, isRevealed: widget.isRevealed);
    }
    return _buildImage(assetPath);
  }

  Widget _buildImage(String path) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Transform.rotate(
          angle: widget.card?.isRotated == true ? 3.1415926535897932 : 0.0,
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.brown[700],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _overlayText!,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
