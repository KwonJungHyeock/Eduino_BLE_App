// Author: eduino
// IR 라인센서 3채널 시각화 (§5.7, 차별 A). 3-LED 표시. 디지털(0/1)·아날로그 모두 대응.

import 'package:flutter/material.dart';

import '../app/theme.dart';

class LineSensorIndicator extends StatelessWidget {
  const LineSensorIndicator({
    super.key,
    required this.line, // (l,c,r) null = 수신 없음
    this.analogMax = 1023, // 아날로그면 이 값 기준 정규화. 0/1 이면 그대로.
    this.count = 3, // 센서 개수: 2(2휠)면 중앙(C) 숨김.
  });

  final ({int l, int c, int r})? line;
  final int analogMax;
  final int count;

  double _intensity(int raw) {
    if (raw <= 1) return raw.toDouble(); // 디지털 0/1
    return (raw / analogMax).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l = line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('IR 라인센서',
            style: AppType.mono(size: 12, color: AppColors.textMuted)),
        Gap.h8,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _cell('L', l == null ? null : _intensity(l.l)),
            if (count >= 3) _cell('C', l == null ? null : _intensity(l.c)),
            _cell('R', l == null ? null : _intensity(l.r)),
          ],
        ),
      ],
    );
  }

  Widget _cell(String label, double? intensity) {
    final on = intensity != null && intensity > 0.5;
    final glow = intensity ?? 0;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: on
                ? AppColors.signal.withValues(alpha: 0.18)
                : AppColors.surface,
            borderRadius: Radii.chip,
            border: Border.all(
              color: on ? AppColors.signal : AppColors.border,
              width: 1.5,
            ),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: AppColors.signal.withValues(alpha: 0.25 * glow),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? AppColors.signal : AppColors.textMuted,
              ),
            ),
          ),
        ),
        Gap.h4,
        Text(label,
            style: AppType.mono(
              size: 12,
              color: on ? AppColors.signal : AppColors.textMuted,
            )),
      ],
    );
  }
}
