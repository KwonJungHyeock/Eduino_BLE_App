// Author: eduino
// 속도 상한 슬라이더 (§5.2·§5.3). 공유 상태(speedCapProvider) 변경 시 SPD 전송(스로틀링).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../providers/car_controller.dart';
import '../providers/ui_providers.dart';

class SpeedCapSlider extends ConsumerWidget {
  const SpeedCapSlider({super.key, this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cap = ref.watch(speedCapProvider);

    void onChanged(double v) {
      final i = v.round();
      ref.read(speedCapProvider.notifier).state = i;
      ref.read(carControllerProvider).setSpeedCap(i);
    }

    final slider = Slider(
      value: cap.toDouble(),
      min: 0,
      max: 100,
      divisions: 20,
      onChanged: onChanged,
    );

    final header = Row(
      children: [
        Text('속도 상한', style: AppType.mono(size: 12, color: AppColors.textMuted)),
        const Spacer(),
        Text('$cap%',
            style: AppType.mono(
                size: 16, weight: FontWeight.w700, color: AppColors.signal)),
      ],
    );

    if (vertical) {
      return Column(
        children: [
          Text('$cap%',
              style: AppType.mono(
                  size: 15, weight: FontWeight.w700, color: AppColors.signal)),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: slider,
            ),
          ),
          Text('SPD', style: AppType.mono(size: 10, color: AppColors.textMuted)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [header, slider],
    );
  }
}
