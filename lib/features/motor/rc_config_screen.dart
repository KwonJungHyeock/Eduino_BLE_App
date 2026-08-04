// Author: eduino
// RC카 설정 — 키트 선택 대신 컨트롤러 설정에서 휠·센서·핀을 지정.
//  구동 방식(2/4휠) · 라인센서 유무 · LED 핀 · 모터 포트(M1~M4).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/motor_config_providers.dart';
import '../../providers/rc_config_providers.dart';
import '../../widgets/home_button.dart';

class RcConfigScreen extends ConsumerWidget {
  const RcConfigScreen({super.key});

  static const List<int> _pins = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = ref.watch(rcConfigProvider).valueOrNull ?? const RcConfig();
    final rcN = ref.read(rcConfigProvider.notifier);
    final kitType = rc.wheels.kitType;
    final ports = ref.watch(motorConfigProvider).valueOrNull?[kitType] ??
        defaultMotorPorts(kitType);
    final slots = motorSlotLabels(kitType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RC카 설정'),
        actions: const [HomeButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            _section('구동 방식'),
            _Card(
              child: Row(
                children: [
                  _WheelSeg(
                    label: '2휠 구동',
                    selected: rc.wheels == WheelType.two,
                    onTap: () => rcN.setWheels(WheelType.two),
                  ),
                  Gap.w8,
                  _WheelSeg(
                    label: '4휠 구동',
                    selected: rc.wheels == WheelType.four,
                    onTap: () => rcN.setWheels(WheelType.four),
                  ),
                ],
              ),
            ),
            Gap.h24,
            _section('센서'),
            _Card(
              child: Row(
                children: [
                  const Icon(Icons.linear_scale, color: AppColors.signal),
                  Gap.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('IR 라인센서',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        Gap.h4,
                        Text(
                          rc.hasLineSensor
                              ? '사용함 · ${rc.lineSensorCount}개 (${rc.wheels == WheelType.four ? "4휠" : "2휠"})'
                              : '없음 (메탈 RC카 등)',
                          style: AppType.mono(
                              size: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rc.hasLineSensor,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      rcN.setLineSensor(v);
                    },
                  ),
                ],
              ),
            ),
            Gap.h8,
            Text('라인센서 개수는 구동 방식에 따라 자동 결정돼요(2휠 2개 · 4휠 3개).',
                style: AppType.mono(
                    size: 11, color: AppColors.textMuted, height: 1.5)),
            Gap.h24,
            _section('출력 핀'),
            _Card(
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.signal),
                  Gap.w12,
                  const Expanded(
                    child: Text('LED 핀',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  DropdownButton<int>(
                    value: rc.ledPin,
                    underline: const SizedBox.shrink(),
                    borderRadius: Radii.card,
                    items: [
                      for (final p in _pins)
                        DropdownMenuItem(
                          value: p,
                          child: Text('D$p', style: AppType.mono(size: 14)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        HapticFeedback.selectionClick();
                        rcN.setLedPin(v);
                      }
                    },
                  ),
                ],
              ),
            ),
            Gap.h24,
            _section('모터 포트 (모터 쉴드 M1~M4)'),
            _Card(
              child: Column(
                children: [
                  for (var i = 0; i < slots.length; i++) ...[
                    if (i > 0) const Divider(height: Gap.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(slots[i],
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        DropdownButton<MotorPort>(
                          value: i < ports.length ? ports[i] : MotorPort.m1,
                          underline: const SizedBox.shrink(),
                          borderRadius: Radii.card,
                          items: [
                            for (final p in MotorPort.values)
                              DropdownMenuItem(
                                value: p,
                                child: Text(p.label,
                                    style: AppType.mono(size: 14)),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(motorConfigProvider.notifier)
                                  .setPort(kitType, i, v);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Gap.h16,
            Text('앱 설정과 아두이노 스케치의 포트/핀을 같게 맞춰주세요.',
                style: AppType.mono(
                    size: 11, color: AppColors.textMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: Text(t,
            style: AppType.mono(
                size: 12, color: AppColors.textMuted, letterSpacing: 2)),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(color: AppColors.border),
          boxShadow: Shadows.soft,
        ),
        child: child,
      );
}

class _WheelSeg extends StatelessWidget {
  const _WheelSeg({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.signal.withValues(alpha: 0.14)
                : AppColors.baseBg,
            borderRadius: Radii.chip,
            border: Border.all(
              color: selected ? AppColors.signal : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              style: AppType.mono(
                size: 14,
                weight: FontWeight.w700,
                color: selected ? AppColors.signal : AppColors.textMuted,
              )),
        ),
      ),
    );
  }
}
