// Author: eduino
// Living Twin — "살아있는 집 씬"(스마트 홈). 수신 센서값/액추에이터 상태를 실내 단면으로 표현.
//   에어컨 ON → 냉기/눈송이 + 쿨 틴트 · 현관문 OPEN → 문 여닫힘 · RGB → 방 앰비언트 색
//   침입자 경보 ON → 붉은 테두리 펄스 + 사이렌 · 온·습도 → 벽 온도계 수신값 표시.
//   미연결(live=false) → 씬 desaturate + "연결하면 집이 살아납니다"(팜과 동일 패턴).
// 아트는 RGB 색이 잘 보이도록 중립·아늑한 실내 톤.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class HouseState {
  const HouseState({
    this.temp,
    this.humi,
    this.acOn = false,
    this.doorOpen = false,
    this.alarmOn = false,
    this.intrusion = false,
    this.ledColor,
    this.live = false,
  });
  final double? temp; // ℃
  final double? humi; // %
  final bool acOn;
  final bool doorOpen;
  final bool alarmOn; // 경계(armed) — arm/disarm 1/0.
  final bool intrusion; // 실제 침입 감지(펌웨어 신호) — 현재 미수신, 예약.
  final Color? ledColor;
  final bool live;

  bool get hasData => temp != null || humi != null;
}

class LivingHouse extends StatefulWidget {
  const LivingHouse({super.key, required this.state});
  final HouseState state;

  @override
  State<LivingHouse> createState() => _LivingHouseState();
}

class _LivingHouseState extends State<LivingHouse>
    with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  late final AnimationController _door = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: widget.state.doorOpen ? 1 : 0);

  static const List<double> _mono = <double>[
    0.5276, 0.4291, 0.0433, 0, 14, //
    0.1276, 0.8291, 0.0433, 0, 14, //
    0.1276, 0.4291, 0.4433, 0, 14, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void didUpdateWidget(covariant LivingHouse old) {
    super.didUpdateWidget(old);
    if (widget.state.doorOpen != old.state.doorOpen) {
      widget.state.doorOpen ? _door.forward() : _door.reverse();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _door.dispose();
    super.dispose();
  }

  Widget _badge(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.92),
              borderRadius: Radii.pill,
            ),
            child: Text(label,
                style: AppType.mono(
                    size: 10, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final live = s.live;
    return ClipRRect(
      borderRadius: Radii.cardLg,
      child: AspectRatio(
        aspectRatio: 1.9,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _door]),
          builder: (context, _) {
            final scene = CustomPaint(
              painter: _HousePainter(state: s, t: _loop.value, door: _door.value),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: live
                      ? scene
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix(_mono),
                          child: scene,
                        ),
                ),
                // 실제 침입 감지(펌웨어 신호) — 강한 붉은 펄스. 예약(현 펌웨어 미수신).
                if (live && s.intrusion) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: Radii.cardLg,
                          border: Border.all(
                            color: AppColors.accent.withValues(
                                alpha: 0.4 + 0.5 * (0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi))),
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _badge(Icons.notifications_active, '침입 발생',
                        AppColors.accent),
                  ),
                ]
                // 경계 중(armed) — 차분한 보안 표시(과잉 경보 방지).
                else if (live && s.alarmOn) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: Radii.cardLg,
                          border: Border.all(
                            color: AppColors.signal.withValues(
                                alpha: 0.22 + 0.12 * (0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi))),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _badge(Icons.shield_outlined, '경계 중',
                        AppColors.signal),
                  ),
                ],
                // 에어컨 배지(우상단).
                if (live && s.acOn)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.signal.withValues(alpha: 0.92),
                        borderRadius: Radii.pill,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.ac_unit, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('냉방 중',
                              style: AppType.mono(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                // 미연결 대기 오버레이.
                if (!live)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Align(
                        alignment: const Alignment(0, -0.62),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: Radii.pill,
                            boxShadow: Shadows.soft,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.home_rounded,
                                  color: AppColors.signal, size: 16),
                              const SizedBox(width: 6),
                              Text('연결하면 집이 살아나요',
                                  style: AppType.mono(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: AppColors.listTitle)),
                            ],
                          ),
                        ),
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
}

class _HousePainter extends CustomPainter {
  _HousePainter({required this.state, required this.t, required this.door});
  final HouseState state;
  final double t; // 0..1 애니메이션 위상
  final double door; // 0(닫힘)..1(열림)

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final roofY = h * 0.26;
    final floorY = h * 0.80;

    // 1) 바깥 배경(하늘).
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFDCEBF7));

    // 2) 지붕(삼각) + 처마.
    final roof = Path()
      ..moveTo(w * 0.04, roofY)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.96, roofY)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF9C6B4F));
    canvas.drawRect(Rect.fromLTRB(w * 0.03, roofY, w * 0.97, roofY + 6),
        Paint()..color = const Color(0xFF7E5641));

    // 3) 벽(중립 웜톤 — RGB 앰비언트가 잘 보이게).
    final wall = Rect.fromLTRB(w * 0.06, roofY, w * 0.94, h);
    canvas.drawRect(wall, Paint()..color = const Color(0xFFF2E9DC));
    // 바닥(원목).
    canvas.drawRect(Rect.fromLTRB(wall.left, floorY, wall.right, h),
        Paint()..color = const Color(0xFFD8BD95));

    // 4) RGB 앰비언트 틴트 — 방 전체 은은한 색(끄기=없음).
    final led = state.ledColor;
    if (led != null) {
      canvas.drawRect(
        Rect.fromLTRB(wall.left, roofY, wall.right, h),
        Paint()..color = led.withValues(alpha: 0.30),
      );
    }

    // 5) 창문(좌측 벽) — 유리 + 십자 프레임.
    final win = Rect.fromLTWH(w * 0.12, h * 0.36, w * 0.20, h * 0.22);
    canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(4)),
        Paint()..color = const Color(0xFFBFE3FF));
    final winFrame = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
        RRect.fromRectAndRadius(win, const Radius.circular(4)), winFrame);
    canvas.drawLine(win.centerLeft, win.centerRight, winFrame);
    canvas.drawLine(win.topCenter, win.bottomCenter, winFrame);

    // 6) 벽 온도계 플라크 — 수신 온·습도 표시.
    _thermo(canvas, w * 0.13, h * 0.30);

    // 7) 소파(중앙) — 중립 톤.
    _sofa(canvas, w * 0.40, floorY);

    // 8) 화분(바닥 우측, 문 옆).
    _plant(canvas, w * 0.63, floorY);

    // 9) 에어컨(우상단 벽) + 냉기/눈송이.
    _aircon(canvas, w, h, roofY);

    // 10) 현관문(우측) — 여닫힘.
    _door(canvas, w, h, floorY);
  }

  // 벽 온도계 — 수신값(없으면 --).
  void _thermo(Canvas canvas, double x, double y) {
    final rect = Rect.fromLTWH(x, y, 92, 34);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = Colors.white.withValues(alpha: 0.94));
    // 온도계 글리프.
    final gx = x + 14, gy = y + 17;
    canvas.drawLine(Offset(gx, y + 7), Offset(gx, gy + 4),
        Paint()..color = AppColors.mint..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(gx, gy + 7), 4.5, Paint()..color = AppColors.mint);
    final tp = state.temp == null ? '--' : '${state.temp!.round()}℃';
    final hp = state.humi == null ? '' : '${state.humi!.round()}%';
    _text(canvas, tp, Offset(x + 26, y + 5),
        size: 14, weight: FontWeight.w800, color: const Color(0xFF1A1D21));
    _text(canvas, hp, Offset(x + 26, y + 20),
        size: 10, weight: FontWeight.w700, color: const Color(0xFF8A9099));
  }

  void _sofa(Canvas canvas, double x, double floorY) {
    final base = Rect.fromLTWH(x, floorY - 34, 96, 30);
    final col = const Color(0xFF8496AD);
    canvas.drawRRect(
        RRect.fromRectAndCorners(base,
            topLeft: const Radius.circular(8), topRight: const Radius.circular(8)),
        Paint()..color = col);
    // 등받이.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 2, floorY - 52, 22, 22), const Radius.circular(8)),
        Paint()..color = col.withValues(alpha: 0.92));
    // 쿠션.
    for (var i = 0; i < 2; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 20 + i * 38, floorY - 46, 32, 18),
              const Radius.circular(6)),
          Paint()..color = const Color(0xFFAEBBCC));
    }
  }

  void _plant(Canvas canvas, double x, double floorY) {
    // 화분.
    final pot = Path()
      ..moveTo(x - 10, floorY - 16)
      ..lineTo(x + 10, floorY - 16)
      ..lineTo(x + 7, floorY - 2)
      ..lineTo(x - 7, floorY - 2)
      ..close();
    canvas.drawPath(pot, Paint()..color = const Color(0xFFC26B3D));
    // 잎.
    final leaf = Paint()..color = const Color(0xFF4CAF50);
    for (final a in [-0.7, 0.0, 0.7]) {
      final tip = Offset(x + math.sin(a) * 16, floorY - 16 - math.cos(a) * 22);
      final path = Path()
        ..moveTo(x, floorY - 16)
        ..quadraticBezierTo(x + math.sin(a) * 4 - 6, floorY - 30, tip.dx, tip.dy)
        ..quadraticBezierTo(x + math.sin(a) * 4 + 6, floorY - 30, x, floorY - 16);
      canvas.drawPath(path, leaf);
    }
  }

  void _aircon(Canvas canvas, double w, double h, double roofY) {
    final unit = Rect.fromLTWH(w * 0.68, roofY + h * 0.06, w * 0.20, h * 0.09);
    canvas.drawRRect(RRect.fromRectAndRadius(unit, const Radius.circular(7)),
        Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(unit, const Radius.circular(7)),
        Paint()
          ..color = const Color(0xFFD7DDE4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
    // 통풍구 라인.
    for (var i = 1; i <= 3; i++) {
      final y = unit.top + unit.height * i / 4;
      canvas.drawLine(Offset(unit.left + 6, y), Offset(unit.right - 6, y),
          Paint()..color = const Color(0xFFC4CBD3)..strokeWidth = 1.5);
    }
    if (!state.acOn) return;
    // 쿨 틴트(방 전체 살짝 파랗게).
    canvas.drawRect(
      Rect.fromLTRB(w * 0.06, roofY, w * 0.94, h),
      Paint()..color = const Color(0xFF7FC7FF).withValues(alpha: 0.12),
    );
    // 눈송이 — 에어컨 아래로 낙하.
    final flake = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 9; i++) {
      final fx = unit.left + (i * 37.0 % unit.width);
      final range = h - unit.bottom - 6;
      final fy = unit.bottom + ((t * range * 1.2) + i * 26.0) % range;
      canvas.drawCircle(Offset(fx, fy), 2.2, flake);
    }
  }

  void _door(Canvas canvas, double w, double h, double floorY) {
    final x0 = w * 0.72, x1 = w * 0.90;
    final top = h * 0.48, bot = floorY;
    final fw = x1 - x0;
    // 문틀 뒤 바깥 빛(열릴수록 보임).
    canvas.drawRect(Rect.fromLTRB(x0, top, x1, bot),
        Paint()..color = const Color(0xFFFFE9B0));
    // 문틀.
    canvas.drawRect(Rect.fromLTRB(x0 - 3, top - 3, x1 + 3, bot),
        Paint()
          ..color = const Color(0xFF9C6B4F)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
    // 문짝 — 우측(x1) 경첩, 열리면 좌측 자유단이 접힘 + 원근 스큐.
    final freeX = x1 - fw * (1 - door);
    final skew = door * 7;
    final leaf = Path()
      ..moveTo(freeX, top + skew)
      ..lineTo(x1, top)
      ..lineTo(x1, bot)
      ..lineTo(freeX, bot - skew)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF6D4C41));
    // 손잡이.
    canvas.drawCircle(Offset(freeX + 5, (top + bot) / 2), 2.6,
        Paint()..color = const Color(0xFFFFD24B));
  }

  void _text(Canvas canvas, String s, Offset at,
      {double size = 12,
      FontWeight weight = FontWeight.w700,
      Color color = Colors.black}) {
    if (s.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: AppType.mono(size: size, weight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.t != t ||
      old.door != door ||
      old.state.temp != state.temp ||
      old.state.humi != state.humi ||
      old.state.acOn != state.acOn ||
      old.state.alarmOn != state.alarmOn ||
      old.state.ledColor != state.ledColor;
}
