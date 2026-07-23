// Author: eduino
// Living Twin — "살아있는 온실 씬"(B1). 수신 센서값/액추에이터 상태를 그림으로 표현.
//   토양↓ 흙 갈라짐·모종 시듦 / 토양↑ 촉촉·생생 · 온도↑ 하늘 붉어짐 · 습도↑ 안개
//   냉각팬 ON → 팬 회전 + "냉각 중" 배지 · LED 색 → 온실 조명 틴트.
//   미연결(live=false) → 씬 desaturate + "연결하면 살아납니다" 오버레이(대기감).
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
    this.live = false,
  });
  final double? soil; // %
  final double? temp; // ℃
  final double? humi; // %
  final bool fanOn;
  final Color? ledColor;
  final bool live; // 연결(수신 활성) 여부 — false면 desaturate.

  bool get hasData => soil != null || temp != null || humi != null;
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

  // 채도 매트릭스 — live=false 시 씬을 잿빛으로(대기).
  static const List<double> _mono = <double>[
    0.42, 0.28, 0.10, 0, 18, //
    0.32, 0.38, 0.10, 0, 18, //
    0.32, 0.28, 0.20, 0, 18, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final live = s.live;
    return ClipRRect(
      borderRadius: Radii.cardLg,
      child: AspectRatio(
        aspectRatio: 2.0,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final scene = CustomPaint(
              painter: _ScenePainter(state: s, t: _c.value),
            );
            return Stack(
              children: [
                // 씬 — 미연결이면 desaturate 로 "잠든" 상태.
                Positioned.fill(
                  child: live
                      ? scene
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix(_mono),
                          child: scene,
                        ),
                ),
                // 미연결 대기 오버레이(B1 · 코칭 문구 흡수).
                if (!live)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco,
                                  color: AppColors.mint, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text('연결하면 온실이 살아납니다',
                                style: AppType.mono(
                                    size: 12.5,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 냉각 중 배지 + 회전 팬(우상단) — 연결 중에만.
                if (live && s.fanOn)
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
                // 라이브 상태 캡션(좌하단) — 연결 중에만(A4).
                if (live)
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: Radii.pill,
                      ),
                      child: Text(
                        _caption(s),
                        style: AppType.mono(
                            size: 11,
                            weight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // A4. 라이브 상태 요약 — "23℃ · 촉촉" 처럼.
  String _caption(GreenhouseState s) {
    final parts = <String>[];
    if (s.temp != null) parts.add('${s.temp!.round()}℃');
    if (s.soil != null) {
      parts.add(_soilWord(s.soil!));
    } else if (s.humi != null) {
      parts.add('습도 ${s.humi!.round()}%');
    }
    return parts.isEmpty ? '센서 값 받는 중…' : parts.join('  ·  ');
  }

  String _soilWord(double soil) {
    if (soil < 30) return '메마름';
    if (soil < 60) return '보통';
    return '촉촉';
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
    canvas.drawCircle(Offset(w * 0.18, h * 0.24), 15 + hot * 6,
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
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < 5; i++) {
        final x = w * (0.12 + i * 0.19);
        final p = Path()
          ..moveTo(x, groundTop + 4)
          ..lineTo(x + 6, groundTop + 14)
          ..lineTo(x - 4, h - 6);
        canvas.drawPath(p, crack);
      }
    }

    // 4) 모종 — 화분 + 잎 풍성한 식물(A2 · 건강도에 따라 색/처짐).
    _drawPlant(canvas, w, h, groundTop, health, humi);

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

    // 6) 온실(그린하우스) 프레임 — 아치형 유리 구조(A1 · 정체성).
    _drawGreenhouse(canvas, w, h);

    // 7) LED 조명 틴트 — 전체 은은한 색 오버레이.
    final led = state.ledColor;
    if (led != null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = led.withValues(alpha: 0.16),
      );
    }
  }

  // A2. 잎이 풍성한 모종 — 화분 + 흙 봉긋 + 잎 6장(건강↓ 갈변·처짐).
  void _drawPlant(Canvas canvas, double w, double h, double groundTop,
      double health, double humi) {
    final baseX = w * 0.5;
    final potTop = groundTop - 2;

    // 화분(테두리 있는 사다리꼴).
    final potBody = Paint()..color = const Color(0xFFC2703F);
    final pot = Path()
      ..moveTo(baseX - 22, potTop + 2)
      ..lineTo(baseX + 22, potTop + 2)
      ..lineTo(baseX + 15, potTop + 26)
      ..lineTo(baseX - 15, potTop + 26)
      ..close();
    canvas.drawPath(pot, potBody);
    // 화분 테(림).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(baseX - 25, potTop - 4, 50, 9),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFFA85C31),
    );
    // 화분 속 흙(봉긋).
    canvas.drawArc(
      Rect.fromLTWH(baseX - 20, potTop - 4, 40, 12),
      math.pi, math.pi, true,
      Paint()..color = const Color(0xFF5A3D28),
    );

    final leafCol =
        Color.lerp(const Color(0xFF9C7B52), const Color(0xFF3FA34D), health)!;
    final leafDark =
        Color.lerp(const Color(0xFF7E6242), const Color(0xFF2E8540), health)!;
    final sway = math.sin(t * 2 * math.pi) * (1.2 + humi / 100 * 1.6);
    final droop = (1 - health) * 0.55; // 건강↓ 처짐(라디안).
    final scale = 0.78 + health * 0.42; // 건강↓ 작게.
    final rootY = potTop - 2;

    // 짧은 줄기.
    canvas.drawLine(
      Offset(baseX, rootY),
      Offset(baseX + sway, rootY - 14 * scale),
      Paint()
        ..color = leafDark
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 잎 — 아래→위로 6장(좌우 교차 + 상단 중앙).
    void leaf(double from, double angFromUp, double len, Color col) {
      final ox = baseX + sway * (from / 60);
      final oy = rootY - from;
      // 처짐: 각도를 바깥/아래로 밀고 tip 을 살짝 내림.
      final a = angFromUp + angFromUp.sign * droop;
      final tip = Offset(
          ox + math.sin(a) * len, oy - math.cos(a) * len + droop * len * 0.9);
      final wid = len * 0.34;
      final perp = Offset(math.cos(a), math.sin(a)) * wid;
      final mid = Offset((ox + tip.dx) / 2, (oy + tip.dy) / 2);
      final path = Path()
        ..moveTo(ox, oy)
        ..quadraticBezierTo(mid.dx + perp.dx, mid.dy + perp.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx - perp.dx, mid.dy - perp.dy, ox, oy)
        ..close();
      canvas.drawPath(path, Paint()..color = col);
      // 잎맥.
      canvas.drawLine(
          Offset(ox, oy),
          tip,
          Paint()
            ..color = leafDark.withValues(alpha: 0.55)
            ..strokeWidth = 1);
    }

    final s = scale;
    leaf(6 * s, -1.05, 26 * s, leafCol); // 좌하
    leaf(6 * s, 1.05, 26 * s, leafDark); // 우하
    leaf(16 * s, -0.72, 30 * s, leafDark); // 좌중
    leaf(16 * s, 0.72, 30 * s, leafCol); // 우중
    leaf(26 * s, -0.34, 28 * s, leafCol); // 좌상
    leaf(28 * s, 0.18, 32 * s, leafDark); // 중앙 정상
  }

  // A1. 아치형 온실 프레임 — 유리 구조 라인 + 은은한 글라스 필.
  void _drawGreenhouse(Canvas canvas, double w, double h) {
    final inset = w * 0.05;
    final eaveY = h * 0.30;
    final ridgeY = h * 0.07;
    final frame = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 아치 지붕.
    final roof = Path()
      ..moveTo(inset, eaveY)
      ..quadraticBezierTo(w * 0.5, ridgeY, w - inset, eaveY);
    // 유리 필(지붕 아래 아주 옅게).
    final glass = Path.from(roof)
      ..lineTo(w - inset, h)
      ..lineTo(inset, h)
      ..close();
    canvas.drawPath(
        glass, Paint()..color = Colors.white.withValues(alpha: 0.05));

    canvas.drawPath(roof, frame);
    // 좌우 기둥.
    canvas.drawLine(Offset(inset, eaveY), Offset(inset, h), frame);
    canvas.drawLine(Offset(w - inset, eaveY), Offset(w - inset, h), frame);
    // 처마 보.
    canvas.drawLine(Offset(inset, eaveY), Offset(w - inset, eaveY), frame);
    // 용마루 수직 바 + 유리 격자.
    final faint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, ridgeY), Offset(w * 0.5, eaveY), faint);
    canvas.drawLine(Offset(w * 0.28, eaveY), Offset(w * 0.28, h), faint);
    canvas.drawLine(Offset(w * 0.72, eaveY), Offset(w * 0.72, h), faint);
    // 지붕 유리 반사(사선 하이라이트).
    canvas.drawLine(
      Offset(w * 0.34, eaveY - (eaveY - ridgeY) * 0.35),
      Offset(w * 0.46, ridgeY + (eaveY - ridgeY) * 0.15),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
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
