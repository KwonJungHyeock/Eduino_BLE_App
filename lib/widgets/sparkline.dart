// Author: eduino
// 미니 데이터 시각화 — 텔레메트리(거리·온습도·조도 등) 최근 값 추이를 스파크라인으로.
// 부드러운 곡선 + 그라디언트 채움 + 마지막 값 점. 계기판 옆 "살아있는" 데이터 느낌.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/theme.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color = AppColors.signal,
    this.height = 40,
    this.strokeWidth = 2.5,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(values, color, strokeWidth),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.strokeWidth);
  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      // 데이터 부족 시 옅은 기준선.
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1.5,
      );
      return;
    }

    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    final pad = strokeWidth + 1;
    final h = size.height - pad * 2;
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final t = (values[i] - lo) / (hi - lo);
      return Offset(dx * i, pad + h * (1 - t));
    }

    // 부드러운 곡선(카뮬-롬 근사 → 큐빅).
    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 0; i < values.length - 1; i++) {
      final p0 = pointAt(i);
      final p1 = pointAt(i + 1);
      final cx = (p0.dx + p1.dx) / 2;
      line.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // 그라디언트 채움.
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ),
    );

    // 선.
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // 마지막 값 점.
    final last = pointAt(values.length - 1);
    canvas.drawCircle(last, strokeWidth + 2, Paint()..color = Colors.white);
    canvas.drawCircle(last, strokeWidth + 0.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}
