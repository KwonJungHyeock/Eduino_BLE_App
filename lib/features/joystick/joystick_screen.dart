// Author: eduino
// 조이스틱(게임패드) 모드 — 아날로그 스틱 + HUD(속도 게이지·니트로 조향 게이지·전송값) + 속도상한 슬라이더 1개.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/neo_joystick.dart';
import '../../widgets/pressable.dart';
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
    // 중앙 근처 미세 입력 무시(드리프트 방지) 데드존.
    double dz(double x) => x.abs() < 0.06 ? 0.0 : x;
    final throttle = (dz(v.dy) * 100).round().clamp(-100, 100).toInt();
    final steer = (dz(v.dx) * 100).round().clamp(-100, 100).toInt();
    if (throttle != _throttle || steer != _steer) {
      setState(() {
        _throttle = throttle;
        _steer = steer;
      });
    }
    ref.read(carControllerProvider).drive(throttle, steer);
  }

  void _reset() => setState(() {
        _throttle = 0;
        _steer = 0;
      });

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: RiseIn(
                child: _Hud(throttle: _throttle, steer: _steer),
              ),
            ),
            Gap.h12,
            Expanded(
              flex: 5,
              child: RiseIn(
                delay: const Duration(milliseconds: 70),
                child: _StickPanel(
                  enabled: connected,
                  onChanged: _onVector,
                  onReleased: _reset,
                ),
              ),
            ),
            Gap.h12,
            // 속도 상한 슬라이더 — 화면 통틀어 하나만.
            RiseIn(
              delay: const Duration(milliseconds: 140),
              child: _Panel(
                padding: const EdgeInsets.symmetric(
                    horizontal: Gap.md, vertical: Gap.sm),
                child: const SpeedCapSlider(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.throttle, required this.steer});
  final int throttle;
  final int steer;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SpeedGauge(
                value: throttle.abs().toDouble(),
                reverse: throttle < 0,
                label: throttle < 0 ? 'REVERSE' : 'THROTTLE',
                size: 180,
              ),
            ),
          ),
          _NitroSteer(steer: steer),
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
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.signalDeep),
            ),
          ),
        ],
      ),
    );
  }
}

/// 니트로 스타일 조향 게이지 — 중앙에서 좌/우로 초록→노랑→빨강 칸이 차오른다.
class _NitroSteer extends StatelessWidget {
  const _NitroSteer({required this.steer});
  final int steer; // -100..100

  static const int _seg = 8;

  static Color _segColor(int dist) {
    final t = ((dist - 1) / (_seg - 1)).clamp(0.0, 1.0);
    // 초록 → 노랑 → 빨강
    if (t < 0.5) {
      return Color.lerp(
          const Color(0xFF2FBF4F), const Color(0xFFF5C518), t * 2)!;
    }
    return Color.lerp(
        const Color(0xFFF5C518), AppColors.accent, (t - 0.5) * 2)!;
  }

  Widget _cell(bool active, int dist) {
    final c = _segColor(dist);
    return Expanded(
      child: Container(
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: active ? c : AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3),
          boxShadow: active
              ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = (steer.abs() / 100 * _seg).round();
    return Column(
      children: [
        Row(
          children: [
            Text('◀ L',
                style: AppType.mono(size: 10, color: AppColors.textMuted)),
            const Spacer(),
            Text('STEER',
                style: AppType.mono(
                    size: 10, color: AppColors.textMuted, letterSpacing: 2)),
            const Spacer(),
            Text('R ▶',
                style: AppType.mono(size: 10, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // 왼쪽: 바깥(dist=_seg) → 중앙(dist=1)
            for (var p = 0; p < _seg; p++)
              _cell(steer < 0 && (_seg - p) <= activeCount, _seg - p),
            // 중앙 피벗
            Container(
              width: 3,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 오른쪽: 중앙(dist=1) → 바깥(dist=_seg)
            for (var p = 0; p < _seg; p++)
              _cell(steer > 0 && (p + 1) <= activeCount, p + 1),
          ],
        ),
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
                final size =
                    (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight)
                        .clamp(150.0, 300.0)
                        .toDouble();
                return Semantics(
                  label: '주행 조이스틱',
                  child: NeoJoystick(
                    size: size,
                    enabled: enabled,
                    onChanged: onChanged,
                    onReleased: onReleased,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel(
      {required this.child, this.padding = const EdgeInsets.all(Gap.md)});
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
          BoxShadow(
              color: Color(0x0F1B3A6B), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

