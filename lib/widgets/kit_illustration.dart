// Author: eduino
// 교구 커스텀 일러스트 — 사진 에셋 없이 CustomPainter 로 그린 플랫 일러스트.
// 밝고 친근한 교육형 톤(둥근 형태 · 브랜드 코랄/블루/민트). 키트 썸네일·빈화면·헤더에 재사용.
// widgets 는 features 에 의존하지 않도록 자체 enum(KitArt) 사용 — 호출부에서 매핑.

import 'package:flutter/material.dart';

import '../app/theme.dart';

enum KitArt { car, factory, home, farm }

class KitIllustration extends StatelessWidget {
  const KitIllustration({
    super.key,
    required this.art,
    this.size = 96,
    this.showTile = true,
  });

  final KitArt art;
  final double size;
  final bool showTile; // 둥근 배경 타일 표시 여부

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KitPainter(art, showTile)),
    );
  }
}

class _KitPainter extends CustomPainter {
  _KitPainter(this.art, this.showTile);
  final KitArt art;
  final bool showTile;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (showTile) {
      final tile = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(s * 0.22),
      );
      canvas.drawRRect(tile, Paint()..color = _tint);
      canvas.save();
      canvas.clipRRect(tile);
    }
    switch (art) {
      case KitArt.car:
        _car(canvas, size, s);
      case KitArt.factory:
        _factory(canvas, size, s);
      case KitArt.home:
        _home(canvas, size, s);
      case KitArt.farm:
        _farm(canvas, size, s);
    }
    if (showTile) canvas.restore();
  }

  Color get _tint => switch (art) {
        KitArt.car => AppColors.signalTint,
        KitArt.factory => const Color(0xFFEAF3FF),
        KitArt.home => const Color(0xFFE7F8F3),
        KitArt.farm => const Color(0xFFEFF8E7),
      };

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ─────────── RC카 (측면) ───────────
  void _car(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    final bodyW = s * 0.62;
    final bodyH = s * 0.22;
    final bodyTop = size.height * 0.50;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH),
      Radius.circular(s * 0.06),
    );
    // 캐빈(둥근 지붕)
    final cabin = RRect.fromLTRBAndCorners(
      cx - bodyW * 0.28,
      bodyTop - s * 0.16,
      cx + bodyW * 0.20,
      bodyTop + s * 0.02,
      topLeft: Radius.circular(s * 0.10),
      topRight: Radius.circular(s * 0.10),
    );
    canvas.drawRRect(cabin, _fill(AppColors.accentSoft));
    canvas.drawRRect(body, _fill(AppColors.accent));
    // 창문
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW * 0.20, bodyTop - s * 0.11,
            bodyW * 0.30, s * 0.10),
        Radius.circular(s * 0.03),
      ),
      _fill(Colors.white.withValues(alpha: 0.9)),
    );
    // 바퀴
    final wheelY = bodyTop + bodyH;
    final wheelR = s * 0.10;
    for (final dx in [-bodyW * 0.28, bodyW * 0.28]) {
      canvas.drawCircle(
          Offset(cx + dx, wheelY), wheelR, _fill(AppColors.textPrimary));
      canvas.drawCircle(
          Offset(cx + dx, wheelY), wheelR * 0.42, _fill(Colors.white));
    }
    // 안테나 + 신호 점
    canvas.drawLine(
      Offset(cx + bodyW * 0.26, bodyTop),
      Offset(cx + bodyW * 0.34, bodyTop - s * 0.20),
      _stroke(AppColors.signal, s * 0.03),
    );
    canvas.drawCircle(Offset(cx + bodyW * 0.34, bodyTop - s * 0.22),
        s * 0.045, _fill(AppColors.signal));
  }

  // ─────────── 스마트 팩토리 (컨베이어 + 팔) ───────────
  void _factory(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    final beltY = size.height * 0.66;
    final beltW = s * 0.66;
    final belt = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - beltW / 2, beltY, beltW, s * 0.10),
      Radius.circular(s * 0.05),
    );
    canvas.drawRRect(belt, _fill(AppColors.textPrimary.withValues(alpha: 0.85)));
    // 롤러
    for (final t in [0.16, 0.5, 0.84]) {
      canvas.drawCircle(
        Offset(cx - beltW / 2 + beltW * t, beltY + s * 0.14),
        s * 0.045,
        _fill(AppColors.textMuted),
      );
    }
    // 박스(컨베이어 위)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - s * 0.06, beltY - s * 0.14, s * 0.16, s * 0.15),
        Radius.circular(s * 0.02),
      ),
      _fill(AppColors.sun),
    );
    // 로봇 팔(축 + 관절 + 집게)
    final baseX = cx - beltW * 0.44;
    final baseY = beltY - s * 0.02;
    canvas.drawLine(Offset(baseX, baseY),
        Offset(baseX, baseY - s * 0.30), _stroke(AppColors.signal, s * 0.05));
    canvas.drawLine(Offset(baseX, baseY - s * 0.30),
        Offset(cx - s * 0.02, baseY - s * 0.34), _stroke(AppColors.signal, s * 0.05));
    canvas.drawCircle(
        Offset(baseX, baseY - s * 0.30), s * 0.045, _fill(AppColors.signalDeep));
    canvas.drawCircle(Offset(cx - s * 0.02, baseY - s * 0.34), s * 0.05,
        _fill(AppColors.signalDeep));
  }

  // ─────────── 스마트 홈 (집) ───────────
  void _home(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    final wallW = s * 0.44;
    final wallTop = size.height * 0.46;
    final wallH = s * 0.30;
    // 지붕
    final roof = Path()
      ..moveTo(cx - wallW * 0.64, wallTop)
      ..lineTo(cx, wallTop - s * 0.22)
      ..lineTo(cx + wallW * 0.64, wallTop)
      ..close();
    canvas.drawPath(roof, _fill(AppColors.mint));
    // 벽
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - wallW / 2, wallTop, wallW, wallH),
        Radius.circular(s * 0.03),
      ),
      _fill(Colors.white),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - wallW / 2, wallTop, wallW, wallH),
        Radius.circular(s * 0.03),
      ),
      _stroke(AppColors.mint, s * 0.02),
    );
    // 문
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cx - s * 0.05, wallTop + wallH * 0.42, cx + s * 0.05, wallTop + wallH,
        topLeft: Radius.circular(s * 0.04),
        topRight: Radius.circular(s * 0.04),
      ),
      _fill(AppColors.mint),
    );
    // 창문(점등)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + wallW * 0.14, wallTop + wallH * 0.18,
            s * 0.10, s * 0.10),
        Radius.circular(s * 0.02),
      ),
      _fill(AppColors.sun),
    );
  }

  // ─────────── 스마트 팜 (온실) ───────────
  void _farm(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    final gw = s * 0.58;
    final gTop = size.height * 0.40;
    final gBottom = size.height * 0.74;
    final left = cx - gw / 2;
    final right = cx + gw / 2;
    // 온실 아치
    final house = Path()
      ..moveTo(left, gBottom)
      ..lineTo(left, gTop + s * 0.10)
      ..quadraticBezierTo(cx, gTop - s * 0.14, right, gTop + s * 0.10)
      ..lineTo(right, gBottom)
      ..close();
    canvas.drawPath(house, _fill(const Color(0xFF8BD34F).withValues(alpha: 0.22)));
    canvas.drawPath(house, _stroke(const Color(0xFF5FA92E), s * 0.022));
    // 지지 리브
    for (final t in [0.33, 0.66]) {
      final x = left + gw * t;
      canvas.drawLine(Offset(x, gBottom), Offset(x, gTop - s * 0.02),
          _stroke(const Color(0xFF5FA92E).withValues(alpha: 0.5), s * 0.015));
    }
    // 새싹 2개
    void sprout(double dx) {
      final base = Offset(cx + dx, gBottom - s * 0.02);
      canvas.drawLine(base, base + Offset(0, -s * 0.12),
          _stroke(const Color(0xFF3E9E3E), s * 0.02));
      canvas.drawCircle(base + Offset(-s * 0.03, -s * 0.11), s * 0.035,
          _fill(const Color(0xFF57C257)));
      canvas.drawCircle(base + Offset(s * 0.03, -s * 0.13), s * 0.035,
          _fill(const Color(0xFF57C257)));
    }

    sprout(-s * 0.12);
    sprout(s * 0.12);
    // 해(따뜻한 포인트)
    canvas.drawCircle(
        Offset(right - s * 0.02, gTop + s * 0.02), s * 0.05, _fill(AppColors.sun));
  }

  @override
  bool shouldRepaint(_KitPainter old) => old.art != art || old.showTile != showTile;
}
