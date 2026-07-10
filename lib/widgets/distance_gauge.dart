// Author: eduino
// 초음파 거리 게이지 (§5.7). 근접 바 + 장애물 임계 마커. 임계 이하로 근접하면 레드 경고.

import 'package:flutter/material.dart';

import '../app/theme.dart';

class DistanceGauge extends StatelessWidget {
  const DistanceGauge({
    super.key,
    required this.distanceCm, // null = 수신 없음
    required this.thresholdCm, // 장애물 임계(PRM DIST)
    this.maxCm = 100,
  });

  final int? distanceCm;
  final int thresholdCm;
  final int maxCm;

  @override
  Widget build(BuildContext context) {
    final d = distanceCm;
    final hasData = d != null;
    final clamped = hasData ? d.clamp(0, maxCm).toDouble() : 0.0;
    final double frac = (clamped / maxCm).clamp(0.0, 1.0).toDouble();
    final danger = hasData && d <= thresholdCm;
    final barColor = danger ? AppColors.accent : AppColors.signal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('거리',
                style: AppType.mono(size: 12, color: AppColors.textMuted)),
            const Spacer(),
            Text(
              hasData ? '$d' : '--',
              style: AppType.instrument(size: 34, color: barColor),
            ),
            Gap.w8,
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('cm',
                  style: AppType.mono(size: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
        Gap.h8,
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final threshFrac = (thresholdCm.clamp(0, maxCm) / maxCm).toDouble();
            final threshX = (threshFrac * w).clamp(0.0, w - 2).toDouble();
            return SizedBox(
              width: w,
              height: 18,
              child: Stack(
                children: [
                  // 트랙
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: Radii.pill,
                      ),
                    ),
                  ),
                  // 값 바
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: frac,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: Radii.pill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 임계 마커
                  Positioned(
                    left: threshX,
                    top: -3,
                    bottom: -3,
                    child: Container(width: 2, color: AppColors.warn),
                  ),
                ],
              ),
            );
          },
        ),
        Gap.h4,
        Text(
          danger ? '⚠ 장애물 임계 이내' : '임계 ${thresholdCm}cm',
          style: AppType.mono(
            size: 11,
            color: danger ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
