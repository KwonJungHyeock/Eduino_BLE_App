// Author: eduino
// 대형 속도 계기 (§5.2 · §6.4 히어로 비주얼). 270° 방사 아크 + 부드러운 이징 바늘 + 대형 모노 수치.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    super.key,
    required this.value, // 0..100 (throttle 크기 %)
    this.size = 240,
    this.label = 'THROTTLE',
    this.unit = '%',
    this.reverse = false, // 후진 여부(수치 색 강조용)
  });

  final double value;
  final double size;
  final String label;
  final String unit;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: v),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SpeedGaugePainter(animated),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animated.round().toString(),
                    style: AppType.instrument(
                      size: size * 0.30,
                      color: reverse ? AppColors.warn : AppColors.textPrimary,
                    ),
                  ),
                  Gap.h4,
                  Text(
                    '$label · $unit',
                    style: AppType.mono(
                      size: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  _SpeedGaugePainter(this.value);
  final double value; // 0..100

  static const double _startAngle = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 트랙(배경 아크)
    canvas.drawArc(
      rect,
      _startAngle,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = AppColors.border,
    );

    // 눈금(주요 6, 보조 사이)
    final tickPaint = Paint()..strokeWidth = 2;
    for (var i = 0; i <= 10; i++) {
      final t = i / 10;
      final a = _startAngle + _sweep * t;
      final isMajor = i % 2 == 0;
      final outer = center + Offset(math.cos(a), math.sin(a)) * (radius - 16);
      final inner = center +
          Offset(math.cos(a), math.sin(a)) * (radius - (isMajor ? 30 : 24));
      tickPaint.color =
          isMajor ? AppColors.textMuted : AppColors.border;
      canvas.drawLine(inner, outer, tickPaint);
    }

    // 값 아크
    final double frac = (value / 100).clamp(0.0, 1.0).toDouble();
    canvas.drawArc(
      rect,
      _startAngle,
      _sweep * frac,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweep,
          colors: [AppColors.signal, AppColors.warn],
          stops: [0.55, 1.0],
        ).createShader(rect),
    );

    // 바늘
    final a = _startAngle + _sweep * frac;
    final needleEnd = center + Offset(math.cos(a), math.sin(a)) * (radius - 6);
    final needleTail =
        center - Offset(math.cos(a), math.sin(a)) * (radius * 0.12);
    canvas.drawLine(
      needleTail,
      needleEnd,
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 6, Paint()..color = AppColors.textPrimary);
    canvas.drawCircle(center, 3, Paint()..color = AppColors.baseBg);
  }

  @override
  bool shouldRepaint(_SpeedGaugePainter old) => old.value != value;
}
