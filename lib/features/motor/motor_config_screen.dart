// Author: eduino
// 모터 포트 설정 — 논리 바퀴(좌/우 또는 4개)를 실제 쉴드 포트(M1~M4)에 매핑.
// 저장한 매핑은 화면과 펌웨어 가이드에 반영된다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/kit_providers.dart';
import '../../providers/motor_config_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/surface_card.dart';
import '../kit/kit_profile.dart';

class MotorConfigScreen extends ConsumerWidget {
  const MotorConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final config = ref.watch(motorConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('모터 포트 설정')),
      body: SafeArea(
        child: kit == null
            ? _NeedKit()
            : config.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(Gap.md),
                    child: SkeletonList(count: 3)), // D1 로딩=스켈레톤
                error: (e, _) => ErrorRetry(
                    message: '모터 설정을 불러오지 못했어요.\n$e',
                    onRetry: () => ref.invalidate(motorConfigProvider)),
                data: (map) {
                  final ports = map[kit.type] ?? defaultMotorPorts(kit.type);
                  final labels = motorSlotLabels(kit.type);
                  return ListView(
                    padding: const EdgeInsets.all(Gap.md),
                    children: [
                      Text(
                        '${kit.name} — 각 바퀴가 연결된 쉴드 포트를 고르세요. (Adafruit Motor Shield M1~M4)',
                        style: AppType.mono(
                            size: 13, color: AppColors.textMuted, height: 1.5),
                      ),
                      const SizedBox(height: Gap.lg),
                      for (var i = 0; i < labels.length; i++) ...[
                        _SlotRow(
                          label: labels[i],
                          selected: ports[i],
                          onPick: (p) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(motorConfigProvider.notifier)
                                .setPort(kit.type, i, p);
                          },
                        ),
                        Gap.h8,
                      ],
                      Gap.h16,
                      _FirmwareHint(kit: kit, ports: ports, labels: labels),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.label,
    required this.selected,
    required this.onPick,
  });
  final String label;
  final MotorPort selected;
  final ValueChanged<MotorPort> onPick;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.settings_input_component, color: AppColors.signal),
          Gap.w16,
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final p in MotorPort.values)
                GestureDetector(
                  onTap: () => onPick(p),
                  child: Container(
                    width: 40,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p == selected
                          ? AppColors.signal
                          : AppColors.surfaceHigh,
                      borderRadius: Radii.chip,
                      border: Border.all(
                        color:
                            p == selected ? AppColors.signal : AppColors.border,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: AppType.mono(
                        size: 12,
                        weight: FontWeight.w700,
                        color: p == selected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirmwareHint extends StatelessWidget {
  const _FirmwareHint({
    required this.kit,
    required this.ports,
    required this.labels,
  });
  final KitProfile kit;
  final List<MotorPort> ports;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    for (var i = 0; i < labels.length; i++) {
      lines.add('${labels[i]} = ${ports[i].label}');
    }
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.signalTint,
        borderRadius: Radii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: AppColors.signalDeep, size: 18),
              Gap.w8,
              Text('펌웨어와 맞추기',
                  style: AppType.mono(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.signalDeep)),
            ],
          ),
          Gap.h8,
          Text(
            '${lines.join('\n')}\n\n아두이노 스케치에서 AF_DCMotor 번호를 위와 같게 맞추세요. (docs/firmware 참고)',
            style: AppType.mono(
                size: 12, color: AppColors.textPrimary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _NeedKit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.smart_toy_outlined,
      accent: AppColors.accent,
      title: '먼저 교구를 선택하세요',
      message: '모터 포트 설정은 교구(키트)를 고른 뒤 열 수 있어요.',
      actionLabel: '키트 선택',
      onAction: () => context.push(Routes.kit),
    );
  }
}
