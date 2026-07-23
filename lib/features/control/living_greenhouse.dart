// Author: eduino
// Living Twin — "살아있는 온실 씬"(B1). 수신 센서값/액추에이터 상태를 그림으로 표현.
//   토양↓ 흙 갈라짐·식물 시듦 / 토양↑ 촉촉·생생 · 온도↑ 하늘 붉어짐 · 습도↑ 안개
//   냉각팬 ON → 팬 회전 + "냉각 중" 배지 · LED 색 → 온실 조명 틴트.
// 기능이 아니라 "결과 표현 레이어" — 값이 없으면 안정 상태로 표시.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class GreenhouseState {
  const GreenhouseState({
    this.soil,
    this.temp,
    this.humi,
    this.fanOn = false,
    this.ledColor,
  });
  final double? soil; // %
  final double? temp; // ℃
  final double? humi; // %
  final bool fanOn;
  final Color? ledColor;
}

class LivingGreenhouse extends StatefulWidget {
  const LivingGreenhouse({super.key, required this.state});
  final GreenhouseState state;

  @override
  State<LivingGreenhouse> createState() => _LivingGreenhouseState();
}

class _LivingGreenhouseState extends State<LivingGreenhouse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ClipRRect(
      borderRadius: Radii.cardLg,
      child: AspectRatio(
        aspectRatio: 2.0,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScenePainter(state: s, t: _c.value),
                  ),
                ),
                // 냉각 중 배지 + 회전 팬(우상단).
                if (s.fanOn)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.signal.withValues(alpha: 0.92),
                            borderRadius: Radii.pill,
                          ),
                          child: Text('냉각 중',
                              style: AppType.mono(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                        Transform.rotate(
                          angle: _c.value * 2 * math.pi,
                          child: const Icon(Icons.toys,
                              size: 26, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                // 상태 요약 캡션(좌하단).
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(
                    _caption(s),
                    style: AppType.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _caption(GreenhouseState s) {
    final parts = <String>[];
    if (s.temp != null) parts.add('${s.temp!.round()}℃');
    if (s.humi != null) parts.add('습도 ${s.humi!.round()}%');
    if (s.soil != null) parts.add('토양 ${s.soil!.round()}%');
    return parts.isEmpty ? '온실 상태 대기 중…' : parts.join('  ·  ');
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.state, required this.t});
  final GreenhouseState state;
  final double t; // 0..1 애니메이션 위상

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final soil = (state.soil ?? 60).clamp(0, 100).toDouble();
    final temp = state.temp ?? 24;
    final humi = state.humi ?? 50;
    final health = soil / 100; // 0..1

    // 1) 하늘 — 온도↑ 붉어짐.
    final hot = ((temp - 26) / 12).clamp(0.0, 1.0);
    final skyTop = Color.lerp(const Color(0xFFBFE3FF), const Color(0xFFFF8A5C), hot)!;
    final skyBot = Color.lerp(const Color(0xFFE9F7EF), const Color(0xFFFFD3B0), hot)!;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBot],
        ).createShader(Offset.zero & size),
    );

    // 2) 해(온도↑ 붉게/커짐).
    final sun = Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFF5A3C), hot)!;
    canvas.drawCircle(Offset(w * 0.16, h * 0.26), 16 + hot * 6,
        Paint()..color = sun.withValues(alpha: 0.9));

    // 3) 흙 — 토양↓ 마르고 갈라짐 / 토양↑ 촉촉.
    final groundTop = h * 0.66;
    final dry = 1 - health;
    final soilCol = Color.lerp(
        const Color(0xFF6B4A2F), const Color(0xFFB79268), dry)!; // 촉촉→건조
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, w, h),
      Paint()..color = soilCol,
    );
    // 갈라짐(토양 낮을수록 진하게).
    if (dry > 0.4) {
      final crack = Paint()
        ..color = const Color(0xFF3E2A1A).withValues(alpha: (dry - 0.4) * 1.2)
        ..strokeWidth = 1.5;
      for (var i = 0; i < 5; i++) {
        final x = w * (0.12 + i * 0.19);
        final p = Path()..moveTo(x, groundTop + 4);
        p.lineTo(x + 6, groundTop + 14);
        p.lineTo(x - 4, h - 6);
        canvas.drawPath(p, crack..style = PaintingStyle.stroke);
      }
    }

    // 4) 식물 — 화분 + 줄기 + 잎(건강도에 따라 색/처짐).
    final baseX = w * 0.5;
    final potTop = groundTop - 2;
    // 화분
    final potPaint = Paint()..color = const Color(0xFFC26B3D);
    final pot = Path()
      ..moveTo(baseX - 20, potTop)
      ..lineTo(baseX + 20, potTop)
      ..lineTo(baseX + 14, potTop + 22)
      ..lineTo(baseX - 14, potTop + 22)
      ..close();
    canvas.drawPath(pot, potPaint);

    final leafCol =
        Color.lerp(const Color(0xFF8D6E63), const Color(0xFF3FA34D), health)!;
    final stem = Paint()
      ..color = leafCol
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final stemH = 30 + health * 24; // 건강할수록 큼
    final sway = math.sin(t * 2 * math.pi) * (1.5 + humi / 100 * 2);
    final topY = potTop - stemH;
    canvas.drawLine(Offset(baseX, potTop), Offset(baseX + sway, topY), stem);

    // 잎 3쌍 — 건강↓ 처짐(droop).
    final droop = (1 - health) * 0.9; // 라디안 추가 처짐
    void leaf(double atY, double dir) {
      final ang = dir * (0.7 + droop);
      final lx = baseX + sway * (atY / topY);
      final len = 12 + health * 8;
      final tip = Offset(lx + math.cos(ang) * len * dir.sign.abs() * dir,
          atY + math.sin(ang.abs()) * len * (0.4 + droop));
      final leafPaint = Paint()..color = leafCol;
      final path = Path()
        ..moveTo(lx, atY)
        ..quadraticBezierTo(lx + dir * 8, atY - 2 + droop * 10, tip.dx, tip.dy)
        ..quadraticBezierTo(lx + dir * 4, atY + 6 + droop * 10, lx, atY);
      canvas.drawPath(path, leafPaint);
    }

    leaf(potTop - stemH * 0.55, -1);
    leaf(potTop - stemH * 0.75, 1);
    leaf(topY + 4, -1);

    // 5) 안개 — 습도↑ 하얀 반투명 띠.
    final fog = ((humi - 60) / 40).clamp(0.0, 1.0);
    if (fog > 0) {
      for (var i = 0; i < 3; i++) {
        final y = groundTop - 30 - i * 16 + math.sin((t + i * 0.3) * 2 * math.pi) * 3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * (0.1 + i * 0.05), y, w * 0.8, 12),
              const Radius.circular(8)),
          Paint()
            ..color = Colors.white.withValues(alpha: fog * 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // 6) LED 조명 틴트 — 전체 은은한 색 오버레이.
    final led = state.ledColor;
    if (led != null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = led.withValues(alpha: 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.t != t ||
      old.state.soil != state.soil ||
      old.state.temp != state.temp ||
      old.state.humi != state.humi ||
      old.state.fanOn != state.fanOn ||
      old.state.ledColor != state.ledColor;
}
