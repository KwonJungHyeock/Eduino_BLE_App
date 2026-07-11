// Author: eduino
// 방향 다이얼 — 다크 계기판(디지털 클러스터) 안에 들어가는 커스텀 인스트루먼트.
// 8방향 링 + 활성 방향으로 향하는 글로우 화살표. 현재 전송 방향을 한눈에.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class DirectionDial extends StatelessWidget {
  const DirectionDial({
    super.key,
    required this.angle, // 라디안(0=위, 시계방향). null = 비활성(정지/대기).
    this.size = 72,
    this.color = const Color(0xFF7CE0C3), // 디지털 그린
    this.idleColor = const Color(0x33FFFFFF),
  });

  /// 8방향 문자열(F/B/L/R/FL/FR/BL/BR) → 각도. 그 외 null.
  static double? angleForMove(String? dir) {
    switch (dir) {
      case 'F':
        return 0;
      case 'FR':
        return math.pi * 0.25;
      case 'R':
        return math.pi * 0.5;
      case 'BR':
        return math.pi * 0.75;
      case 'B':
        return math.pi;
      case 'BL':
        return math.pi * 1.25;
      case 'L':
        return math.pi * 1.5;
      case 'FL':
        return math.pi * 1.75;
    }
    return null;
  }

  final double? angle;
  final double size;
  final Color color;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DialPainter(
          angle: angle,
          color: color,
          idleColor: idleColor,
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.angle,
    required this.color,
    required this.idleColor,
  });

  final double? angle;
  final Color color;
  final Color idleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // 바깥 링.
    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = idleColor,
    );

    // 8방향 도트.
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4; // 화면좌표(위=-90°)
      final p = center + Offset(math.cos(a), math.sin(a)) * (r - 8);
      final isActive = angle != null &&
          ((_norm(a + math.pi / 2 - angle!)).abs() < 0.01);
      canvas.drawCircle(
        p,
        isActive ? 3.2 : 2.0,
        Paint()..color = isActive ? color : idleColor,
      );
    }

    if (angle == null) {
      // 정지/대기: 중앙 점.
      canvas.drawCircle(center, 4, Paint()..color = idleColor);
      return;
    }

    // 활성 화살표(위 기준에서 angle 만큼 회전).
    final dir = Offset(math.cos(angle! - math.pi / 2),
        math.sin(angle! - math.pi / 2));
    final tip = center + dir * (r - 12);
    final tail = center - dir * (r * 0.35);

    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // 화살촉.
    final perp = Offset(-dir.dy, dir.dx);
    final base = center + dir * (r - 22);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * 6, base.dy + perp.dy * 6)
      ..lineTo(base.dx - perp.dx * 6, base.dy - perp.dy * 6)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // 중심 허브.
    canvas.drawCircle(center, 4, Paint()..color = color);
    canvas.drawCircle(center, 1.6, Paint()..color = const Color(0xFF0E1726));
  }

  // -pi..pi 정규화.
  double _norm(double a) {
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a < -math.pi) {
      a += 2 * math.pi;
    }
    return a;
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.angle != angle || old.color != color;
}
