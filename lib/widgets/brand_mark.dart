// Author: eduino
// 브랜드 마크 — 코드로 그린 EDUINO 심볼(마이크로컨트롤러 칩 + 블루투스 룬).
// 사진/SVG 에셋 없이 CustomPainter 로만 구성. AnimatedBrandMark 는 인트로에서
// "그려지는" 연출(칩 등장 → 핀 팝 → 블루투스 룬 스트로크 드로우온)을 준다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// 정적 브랜드 마크. progress 1.0 = 완성 상태.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 120, this.progress = 1.0});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandMarkPainter(progress)),
    );
  }
}

/// 인트로용 애니메이션 마크 — 한 번 재생.
class AnimatedBrandMark extends StatefulWidget {
  const AnimatedBrandMark({super.key, this.size = 120, this.onDone});

  final double size;
  final VoidCallback? onDone;

  @override
  State<AnimatedBrandMark> createState() => _AnimatedBrandMarkState();
}

class _AnimatedBrandMarkState extends State<AnimatedBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.intro,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, _) => CustomPaint(
          painter: _BrandMarkPainter(curved.value),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter(this.progress);

  final double progress;

  // 세 구간으로 나눈 진행도.
  double get _board => _seg(0.0, 0.55);
  double get _pins => _seg(0.30, 0.72);
  double get _rune => _seg(0.52, 1.0);

  double _seg(double a, double b) =>
      ((progress - a) / (b - a)).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final boardSize = s * 0.72;
    final rect = Rect.fromCenter(
        center: center, width: boardSize, height: boardSize);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.20));

    // 등장 스케일(칩이 살짝 커지며 나타남).
    final scale = 0.82 + 0.18 * Curves.easeOutBack.transform(_board);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    // 핀(칩 다리) — 좌우로 톡톡 나오는 느낌.
    _drawPins(canvas, rect, s);

    // 칩 보드(코랄 그라디언트) + 부드러운 그림자.
    final boardPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentSoft, AppColors.accent],
      ).createShader(rect);
    canvas.drawShadow(
        Path()..addRRect(rr), const Color(0x55EE4C57), s * 0.06, true);
    canvas.drawRRect(rr, boardPaint..color = boardPaint.color.withValues(alpha: _board));

    // 보드 안쪽 하이라이트 링.
    final inset = rect.deflate(s * 0.09);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(s * 0.13)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..color = Colors.white.withValues(alpha: 0.35 * _board),
    );

    // 블루투스 룬 — 스트로크 드로우온.
    _drawRune(canvas, rect, s);

    canvas.restore();
  }

  void _drawPins(Canvas canvas, Rect r, double s) {
    if (_pins <= 0) return;
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.85 * _pins)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.03;
    final pinLen = s * 0.06 * _pins;
    for (var i = 0; i < 3; i++) {
      final y = r.top + r.height * (0.30 + 0.20 * i);
      // 좌
      canvas.drawLine(
          Offset(r.left, y), Offset(r.left - pinLen, y), paint);
      // 우
      canvas.drawLine(
          Offset(r.right, y), Offset(r.right + pinLen, y), paint);
    }
    for (var i = 0; i < 3; i++) {
      final x = r.left + r.width * (0.30 + 0.20 * i);
      canvas.drawLine(Offset(x, r.top), Offset(x, r.top - pinLen), paint);
      canvas.drawLine(
          Offset(x, r.bottom), Offset(x, r.bottom + pinLen), paint);
    }
  }

  void _drawRune(Canvas canvas, Rect board, double s) {
    if (_rune <= 0) return;
    // 룬 영역(보드 중앙).
    final area = board.deflate(board.width * 0.26);
    Offset p(double nx, double ny) =>
        Offset(area.left + area.width * nx, area.top + area.height * ny);

    // 블루투스 단일 스트로크(두 삼각형 + 스파인).
    final path = Path()
      ..moveTo(p(0.30, 0.30).dx, p(0.30, 0.30).dy)
      ..lineTo(p(0.72, 0.70).dx, p(0.72, 0.70).dy)
      ..lineTo(p(0.50, 0.88).dx, p(0.50, 0.88).dy)
      ..lineTo(p(0.50, 0.12).dx, p(0.50, 0.12).dy)
      ..lineTo(p(0.72, 0.30).dx, p(0.72, 0.30).dy)
      ..lineTo(p(0.30, 0.70).dx, p(0.30, 0.70).dy);

    // 부분 경로 추출로 "그려지는" 효과.
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var drawn = total * _rune;
    final partial = Path();
    for (final m in metrics) {
      if (drawn <= 0) break;
      final take = math.min(drawn, m.length);
      partial.addPath(m.extractPath(0, take), Offset.zero);
      drawn -= take;
    }

    canvas.drawPath(
      partial,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.progress != progress;
}
