// Author: eduino
// Living Twin — "가동 라인 씬"(스마트 팩토리). 명령 상태를 컨베이어 라인으로 표현.
//   가동('1') → 벨트/롤러 회전·물체 흐름·분류 서보 스윙 / 중지('0') → 전부 정지(freeze).
//   ★정직성(A3): 벨트 위 물체·분류는 "작동 미리보기"(연출). 앱은 분류 결과를 수신하지
//   않으므로 "빨강 N개" 같은 가짜 카운트 금지 — 표시 가능한 사실은 가동/정지 + 가동 시간뿐.
//   미연결 → desaturate + "연결하면 라인이 돌아갑니다" 오버레이(팜·홈과 동일 패턴).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FactoryState {
  const FactoryState({this.running = false, this.live = false});
  final bool running; // 컨베이어 가동('1') 여부.
  final bool live; // 연결 여부.
}

class LivingFactory extends StatefulWidget {
  const LivingFactory({super.key, required this.state});
  final FactoryState state;

  @override
  State<LivingFactory> createState() => _LivingFactoryState();
}

class _LivingFactoryState extends State<LivingFactory>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  Timer? _tick;
  int _secs = 0; // 가동 시간(앱 카운트) — 연결/명령 무관, 실제 표시 가능한 사실.

  static const List<double> _mono = <double>[
    0.5276, 0.4291, 0.0433, 0, 14, //
    0.1276, 0.8291, 0.0433, 0, 14, //
    0.1276, 0.4291, 0.4433, 0, 14, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.state.running && widget.state.live) {
        setState(() => _secs++);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LivingFactory old) {
    super.didUpdateWidget(old);
    // 가동 시작(off→on) 시 가동 시간 리셋.
    if (widget.state.running && !old.state.running) _secs = 0;
  }

  @override
  void dispose() {
    _tick?.cancel();
    _loop.dispose();
    super.dispose();
  }

  String get _uptime {
    final m = (_secs ~/ 60).toString().padLeft(2, '0');
    final s = (_secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.state;
    final live = st.live;
    final running = live && st.running;
    return ClipRRect(
      borderRadius: Radii.cardLg,
      child: AspectRatio(
        aspectRatio: 1.9,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final scene = CustomPaint(
              painter: _LinePainter(running: running, t: _loop.value),
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
                // 상태 배지: 가동 중(초록) / 정지(회색) — 명령 상태 반영(A2).
                if (live)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: (running ? AppColors.mint : AppColors.chipGrayIcon)
                                .withValues(alpha: 0.95),
                            borderRadius: Radii.pill,
                          ),
                          child: Row(
                            children: [
                              Icon(running ? Icons.play_arrow : Icons.stop,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(running ? '가동 중' : '정지',
                                  style: AppType.mono(
                                      size: 10,
                                      weight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 가동 시간(앱 카운트) — 유일하게 정직하게 표시 가능한 값.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: Radii.pill,
                          ),
                          child: Text('가동 $_uptime',
                              style: AppType.mono(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                // 정직성 라벨(A3) — 물체/분류는 연출.
                if (live)
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Text('작동 미리보기',
                        style: AppType.mono(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ),
                // 미연결 대기 오버레이(A4).
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
                              const Icon(Icons.precision_manufacturing,
                                  color: AppColors.signal, size: 16),
                              const SizedBox(width: 6),
                              Text('연결하면 라인이 돌아갑니다',
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

class _LinePainter extends CustomPainter {
  _LinePainter({required this.running, required this.t});
  final bool running;
  final double t; // 0..1 애니메이션 위상

  static const _blue = AppColors.signal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final phase = running ? t : 0.0; // 정지 시 모션 freeze.

    // 배경 — 공장 벽/바닥(중립).
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEDF1F5));
    final floorY = h * 0.82;
    canvas.drawRect(Rect.fromLTRB(0, floorY, w, h),
        Paint()..color = const Color(0xFFD5DBE2));

    // 컨베이어 벨트.
    final beltL = w * 0.08, beltR = w * 0.60;
    final beltY = h * 0.50, beltH = h * 0.11;
    final beltMidY = beltY + beltH / 2;
    final beltRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(beltL, beltY, beltR, beltY + beltH),
        Radius.circular(beltH / 2));
    canvas.drawRRect(beltRect, Paint()..color = const Color(0xFF3A4250));
    // 벨트 트레드(이동).
    final tread = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    final gap = 22.0;
    final off = (phase * gap);
    for (double x = beltL + off; x < beltR; x += gap) {
      canvas.drawLine(Offset(x, beltY + 4), Offset(x, beltY + beltH - 4), tread);
    }

    // 롤러(양끝, 회전 스포크).
    final rollerR = beltH * 0.62;
    _roller(canvas, Offset(beltL, beltMidY), rollerR, phase);
    _roller(canvas, Offset(beltR, beltMidY), rollerR, phase);

    // 물체(박스) — 벨트 위를 좌→우로 흐름(연출).
    const nBox = 3;
    for (var i = 0; i < nBox; i++) {
      final p = ((phase + i / nBox) % 1.0);
      final bx = beltL + 14 + (beltR - beltL - 28) * p;
      final by = beltY - 12;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - 9, by, 18, 14), const Radius.circular(3));
      canvas.drawRRect(r, Paint()..color = const Color(0xFFC79A5B));
      canvas.drawRRect(
          r,
          Paint()
            ..color = const Color(0xFF9E7A44)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
    }

    // 분류 서보(벨트 끝 위) — 스윙 암.
    final pivot = Offset(beltR + w * 0.03, beltY - h * 0.02);
    final swing = math.sin(phase * 2 * math.pi) * 0.5; // -0.5..0.5 rad
    final armLen = h * 0.16;
    final armEnd = Offset(pivot.dx + math.sin(swing) * armLen,
        pivot.dy + math.cos(swing) * armLen);
    canvas.drawCircle(pivot, 5, Paint()..color = _blue);
    canvas.drawLine(
        pivot,
        armEnd,
        Paint()
          ..color = _blue
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(armEnd, 4, Paint()..color = const Color(0xFF0E5FC0));

    // 수거함 A/B/C.
    final binY = floorY - h * 0.16, binH = h * 0.16, binW = w * 0.075;
    final labels = ['A', 'B', 'C'];
    final centers = [w * 0.72, w * 0.82, w * 0.92];
    for (var i = 0; i < 3; i++) {
      final cx = centers[i];
      final bin = Path()
        ..moveTo(cx - binW / 2, binY)
        ..lineTo(cx + binW / 2, binY)
        ..lineTo(cx + binW / 2 - 3, binY + binH)
        ..lineTo(cx - binW / 2 + 3, binY + binH)
        ..close();
      canvas.drawPath(bin, Paint()..color = const Color(0xFFB9C2CD));
      canvas.drawPath(
          bin,
          Paint()
            ..color = _blue.withValues(alpha: 0.5)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
      _text(canvas, labels[i], Offset(cx - 4, binY + binH * 0.34),
          size: 13, color: const Color(0xFF3A4250));
    }

    // 분류되는 물체(연출) — 서보 끝에서 가리키는 함으로 낙하.
    if (running) {
      final drop = phase; // 0..1
      final targetIdx = ((swing + 0.5) / 1.0 * 2).round().clamp(0, 2);
      final tx = centers[targetIdx];
      final ox = armEnd.dx + (tx - armEnd.dx) * drop;
      final oy = armEnd.dy + (binY - armEnd.dy) * drop;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(ox - 6, oy - 5, 12, 10), const Radius.circular(2)),
          Paint()..color = const Color(0xFFC79A5B));
    }

    // 지지 다리.
    final leg = Paint()
      ..color = const Color(0xFF8894A3)
      ..strokeWidth = 4;
    canvas.drawLine(Offset(beltL + 10, beltY + beltH), Offset(beltL + 10, floorY), leg);
    canvas.drawLine(Offset(beltR - 10, beltY + beltH), Offset(beltR - 10, floorY), leg);
  }

  void _roller(Canvas canvas, Offset c, double r, double phase) {
    canvas.drawCircle(c, r, Paint()..color = _blue);
    canvas.drawCircle(c, r,
        Paint()..color = const Color(0xFF0E5FC0)..strokeWidth = 2..style = PaintingStyle.stroke);
    final a = phase * 2 * math.pi;
    final spoke = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2;
    for (var k = 0; k < 2; k++) {
      final ang = a + k * math.pi / 2;
      canvas.drawLine(
          Offset(c.dx - math.cos(ang) * r * 0.7, c.dy - math.sin(ang) * r * 0.7),
          Offset(c.dx + math.cos(ang) * r * 0.7, c.dy + math.sin(ang) * r * 0.7),
          spoke);
    }
  }

  void _text(Canvas canvas, String s, Offset at,
      {double size = 12,
      FontWeight weight = FontWeight.w800,
      Color color = Colors.black}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: AppType.mono(size: size, weight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.t != t || old.running != running;
}
