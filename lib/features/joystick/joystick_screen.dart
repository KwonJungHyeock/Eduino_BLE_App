// Author: eduino
// 조이스틱 모드 — Neo Cockpit 메인 (§5.2). 중앙 대형 속도 텔레메트리, 좌 조이스틱, 우 속도상한+정지.
// 가로/세로 모두 대응. 아날로그 벡터 → DRV 전송(스로틀링은 CarController).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/neo_joystick.dart';
import '../../widgets/speed_cap_slider.dart';
import '../../widgets/speed_gauge.dart';
import '../../widgets/surface_card.dart';

class JoystickScreen extends ConsumerStatefulWidget {
  const JoystickScreen({super.key});

  @override
  ConsumerState<JoystickScreen> createState() => _JoystickScreenState();
}

class _JoystickScreenState extends ConsumerState<JoystickScreen> {
  int _throttle = 0; // -100..100
  int _steer = 0; // -100..100

  void _onVector(Offset v) {
    final throttle = (v.dy * 100).round().clamp(-100, 100).toInt();
    final steer = (v.dx * 100).round().clamp(-100, 100).toInt();
    if (throttle != _throttle || steer != _steer) {
      setState(() {
        _throttle = throttle;
        _steer = steer;
      });
    }
    ref.read(carControllerProvider).drive(throttle, steer);
  }

  void _onReleased() {
    setState(() {
      _throttle = 0;
      _steer = 0;
    });
    ref.read(carControllerProvider).stop();
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    final gauge = SpeedGauge(
      value: _throttle.abs().toDouble(),
      reverse: _throttle < 0,
      label: _throttle < 0 ? 'REVERSE' : 'THROTTLE',
    );

    final joystick = LayoutBuilder(
      builder: (context, c) {
        final size = (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight)
            .clamp(160.0, 260.0)
            .toDouble();
        return Center(
          child: NeoJoystick(
            size: size,
            enabled: connected,
            onChanged: _onVector,
            onReleased: _onReleased,
          ),
        );
      },
    );

    final rightPanel = Column(
      children: [
        Expanded(child: SurfaceCard(child: const SpeedCapSlider(vertical: true))),
        Gap.h16,
        _StopButton(onTap: () {
          HapticFeedback.heavyImpact();
          ref.read(carControllerProvider).stop();
          _onReleased();
        }),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: LayoutBuilder(
          builder: (context, c) {
            final landscape = c.maxWidth > c.maxHeight;
            if (landscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: joystick),
                  Expanded(flex: 5, child: Center(child: gauge)),
                  SizedBox(width: 120, child: rightPanel),
                ],
              );
            }
            // 세로 대응: 게이지 위, 조이스틱+정지 아래, 슬라이더 최하단.
            return Column(
              children: [
                Expanded(flex: 3, child: Center(child: gauge)),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(child: joystick),
                      Gap.w16,
                      _StopButton(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          ref.read(carControllerProvider).stop();
                          _onReleased();
                        },
                      ),
                    ],
                  ),
                ),
                SurfaceCard(child: const SpeedCapSlider()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.pill,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withValues(alpha: 0.14),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stop, color: AppColors.accent, size: 30),
            Text('STOP',
                style: AppType.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}
