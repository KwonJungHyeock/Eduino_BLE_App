// Author: eduino
// 연결 성공 연출 — 확장 링(리플) + 원 스케일 + 체크마크 드로우온. 한 번 재생.
// 사진/로티 없이 CustomPainter 로만 구성. 연결 완료 순간의 피드백.

import 'package:flutter/material.dart';

import '../app/theme.dart';

class SuccessCheck extends StatefulWidget {
  const SuccessCheck({
    super.key,
    this.size = 96,
    this.color = AppColors.signal,
  });

  final double size;
  final Color color;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            CustomPaint(painter: _CheckPainter(_c.value, widget.color)),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.color);
  final double t; // 0..1
  final Color color;

  double _seg(double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // 리플(확장하며 사라짐).
    final ripple = Curves.easeOut.transform(_seg(0.0, 0.85));
    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        center,
        r * (0.6 + 0.5 * ripple),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - ripple) * 0.5),
      );
    }

    // 채워진 원(스케일 인 + 백이징).
    final pop = Curves.easeOutBack.transform(_seg(0.0, 0.5));
    final circleR = r * 0.72 * pop.clamp(0.0, 1.0);
    if (circleR > 0) {
      canvas.drawCircle(center, circleR, Paint()..color = color);
    }

    // 체크마크 드로우온.
    final draw = Curves.easeOut.transform(_seg(0.45, 1.0));
    if (draw > 0) {
      final p1 = center + Offset(-r * 0.26, r * 0.02);
      final p2 = center + Offset(-r * 0.06, r * 0.22);
      final p3 = center + Offset(r * 0.30, -r * 0.20);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white;

      // 두 구간으로 나눠 순차 드로우.
      final path = Path()..moveTo(p1.dx, p1.dy);
      if (draw < 0.5) {
        final k = draw / 0.5;
        path.lineTo(p1.dx + (p2.dx - p1.dx) * k, p1.dy + (p2.dy - p1.dy) * k);
      } else {
        final k = (draw - 0.5) / 0.5;
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(p2.dx + (p3.dx - p2.dx) * k, p2.dy + (p3.dy - p2.dy) * k);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}
