// Author: eduino
// 조이스틱(게임패드) 모드 — 아날로그 스틱 + HUD(속도/조향/전송값) + 대형 STOP.
// 게이밍 컨트롤러 느낌: 블루 글로우 패널, 실시간 DRV 값 표시로 전송 확인까지 된다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/neo_joystick.dart';
import '../../widgets/speed_cap_slider.dart';
import '../../widgets/speed_gauge.dart';

class JoystickScreen extends ConsumerStatefulWidget {
  const JoystickScreen({super.key});

  @override
  ConsumerState<JoystickScreen> createState() => _JoystickScreenState();
}

class _JoystickScreenState extends ConsumerState<JoystickScreen> {
  int _throttle = 0;
  int _steer = 0;

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

  void _reset() {
    setState(() {
      _throttle = 0;
      _steer = 0;
    });
  }

  void _stop() {
    HapticFeedback.heavyImpact();
    ref.read(carControllerProvider).stop();
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: LayoutBuilder(
          builder: (context, c) {
            final landscape = c.maxWidth > c.maxHeight;
            final hud = _Hud(throttle: _throttle, steer: _steer);
            final stick = _StickPanel(
              enabled: connected,
              onChanged: _onVector,
              onReleased: _reset,
            );
            final right = _RightPanel(onStop: _stop);

            if (landscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: stick),
                  Gap.w16,
                  Expanded(flex: 4, child: hud),
                  Gap.w16,
                  SizedBox(width: 116, child: right),
                ],
              );
            }
            return Column(
              children: [
                Expanded(flex: 3, child: hud),
                Gap.h16,
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Expanded(child: stick),
                      Gap.w16,
                      SizedBox(width: 104, child: right),
                    ],
                  ),
                ),
                Gap.h8,
                _CapBar(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 게임패드 HUD — 속도 게이지 + 조향 바 + 실시간 전송값(DRV).
class _Hud extends StatelessWidget {
  const _Hud({required this.throttle, required this.steer});
  final int throttle;
  final int steer;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SpeedGauge(
                value: throttle.abs().toDouble(),
                reverse: throttle < 0,
                label: throttle < 0 ? 'REVERSE' : 'THROTTLE',
                size: 190,
              ),
            ),
          ),
          _SteerBar(steer: steer),
          Gap.h8,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.signalTint,
              borderRadius: Radii.pill,
            ),
            child: Text(
              'DRV: $throttle, $steer',
              style: AppType.mono(
                  size: 13, weight: FontWeight.w700, color: AppColors.signalDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteerBar extends StatelessWidget {
  const _SteerBar({required this.steer});
  final int steer; // -100..100

  @override
  Widget build(BuildContext context) {
    final t = (steer + 100) / 200; // 0..1
    return Column(
      children: [
        Row(
          children: [
            Text('L', style: AppType.mono(size: 11, color: AppColors.textMuted)),
            const Spacer(),
            Text('STEER',
                style: AppType.mono(size: 10, color: AppColors.textMuted, letterSpacing: 2)),
            const Spacer(),
            Text('R', style: AppType.mono(size: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: AppColors.border, borderRadius: Radii.pill),
                  ),
                ),
                // 중앙 기준 인디케이터
                Positioned(
                  left: (t * w - 6).clamp(0.0, w - 12).toDouble(),
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.signal,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StickPanel extends StatelessWidget {
  const _StickPanel({
    required this.enabled,
    required this.onChanged,
    required this.onReleased,
  });
  final bool enabled;
  final void Function(Offset) onChanged;
  final VoidCallback onReleased;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('DRIVE STICK',
                style: AppType.mono(
                    size: 10, color: AppColors.textMuted, letterSpacing: 2)),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, c) {
                final size = (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight)
                    .clamp(160.0, 300.0)
                    .toDouble();
                return NeoJoystick(
                  size: size,
                  enabled: enabled,
                  onChanged: onChanged,
                  onReleased: onReleased,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.onStop});
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _Panel(child: const SpeedCapSlider(vertical: true))),
        Gap.h16,
        _StopButton(onTap: onStop),
      ],
    );
  }
}

class _CapBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      child: const SpeedCapSlider(),
    );
  }
}

/// 게임패드 느낌의 패널 — 블루 보더 + 부드러운 그림자.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(Gap.md)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1B3A6B), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5A5F), AppColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stop, color: Colors.white, size: 30),
            Text('STOP',
                style: AppType.mono(
                    size: 12, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
