// Author: eduino
// 자율주행·실험 모드 ★ 차별 A (§5.7). 수동/자율 토글 + 라이브 텔레메트리 + 실시간 PRM 튜닝.
// 핵심 교육 흐름: "값을 바꾸면 → 로봇 행동이 바뀐다"를 눈으로 확인.
// 메탈 RC카는 IR 미탑재 → 라인 관련 요소 자동 숨김(장애물 회피만 노출).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/distance_gauge.dart';
import '../../widgets/surface_card.dart';

class AutonomousScreen extends ConsumerStatefulWidget {
  const AutonomousScreen({super.key});

  @override
  ConsumerState<AutonomousScreen> createState() => _AutonomousScreenState();
}

class _AutonomousScreenState extends ConsumerState<AutonomousScreen> {
  // PRM 튜닝 대상 초기값(펌웨어 스켈레치 기준 §7.3).
  int _obstDist = 20; // DIST cm
  int _autoSpeed = 60; // SPD 0-100

  bool _auto = false; // 앱이 의도한 현재 모드(펌웨어 응답을 기다리지 않고 즉시 반영).

  void _setMode(DriveMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _auto = mode == DriveMode.auto);
    ref.read(carControllerProvider).setMode(mode);
  }

  void _setParam(PrmKey key, int value) {
    ref.read(carControllerProvider).setParam(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final tele = ref.watch(telemetryProvider);
    final connected = ref.watch(connectionProvider).isConnected;

    // 자율주행(초음파 장애물 회피) 전용 — 라인트레이싱은 별도 화면.
    // 앱 의도 모드를 우선(펌웨어가 MOD 응답을 안 보내도 즉시 전환). 응답이 오면 그걸로 동기화.
    final isAuto = _auto || tele.mode == DriveMode.auto;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          // 수동/자율 토글
          _ModeToggle(
            isAuto: isAuto,
            enabled: connected,
            onChanged: _setMode,
          ),
          Gap.h16,

          // 자율 모드일 때만 실험 계기·튜닝 노출(수동 모드에선 안내).
          if (!isAuto)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_mode, color: AppColors.signal),
                      Gap.w8,
                      Text('자율주행 실험이란?',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Gap.h8,
                  Text(
                    '위 "자율주행" 버튼을 누르면 로봇이 스스로 장애물을 피해 주행합니다.\n'
                    '① 초음파 거리를 실시간으로 확인\n'
                    '② 아래 슬라이더로 임계거리·속도를 바꾸면\n'
                    '   코드 재업로드 없이 로봇 행동이 즉시 달라집니다.\n\n'
                    '"값을 바꾸면 → 로봇이 달라진다"를 눈으로 실험해 보세요.',
                    style: AppType.mono(
                        size: 12, color: AppColors.textMuted, height: 1.7),
                  ),
                ],
              ),
            )
          else ...[
            // 라이브 텔레메트리
            Text('라이브 텔레메트리',
                style: AppType.mono(
                    size: 12,
                    color: AppColors.textMuted,
                    letterSpacing: 2)),
            Gap.h8,
            SurfaceCard(
              child: DistanceGauge(
                distanceCm: tele.distanceCm,
                thresholdCm: _obstDist,
              ),
            ),
            Gap.h24,

            // 실시간 파라미터 튜닝
            Text('실시간 파라미터 튜닝 (PRM)',
                style: AppType.mono(
                    size: 12,
                    color: AppColors.textMuted,
                    letterSpacing: 2)),
            Gap.h8,
            SurfaceCard(
              child: Column(
                children: [
                  _ParamSlider(
                    label: '장애물 임계거리',
                    hint: 'DIST',
                    value: _obstDist,
                    min: 5,
                    max: 80,
                    unit: 'cm',
                    enabled: connected,
                    onChanged: (v) {
                      setState(() => _obstDist = v);
                      _setParam(PrmKey.dist, v);
                    },
                  ),
                  const Divider(height: Gap.lg),
                  _ParamSlider(
                    label: '자율 속도',
                    hint: 'SPD',
                    value: _autoSpeed,
                    min: 0,
                    max: 100,
                    unit: '',
                    enabled: connected,
                    onChanged: (v) {
                      setState(() => _autoSpeed = v);
                      _setParam(PrmKey.spd, v);
                    },
                  ),
                ],
              ),
            ),
            Gap.h16,
            Text(
              '슬라이더를 움직이면 즉시 PRM 명령이 전송됩니다. 코드 재업로드 없이 로봇 동작이 바뀝니다.',
              style: AppType.mono(
                  size: 11, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isAuto,
    required this.enabled,
    required this.onChanged,
  });

  final bool isAuto;
  final bool enabled;
  final void Function(DriveMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.pill,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _seg('수동', Icons.pan_tool_alt_outlined, !isAuto,
                enabled ? () => onChanged(DriveMode.manual) : null),
            _seg('자율주행', Icons.auto_mode, isAuto,
                enabled ? () => onChanged(DriveMode.auto) : null),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool active, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.signal.withValues(alpha: 0.16) : null,
            borderRadius: Radii.pill,
            border: Border.all(
              color: active ? AppColors.signal : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? AppColors.signal : AppColors.textMuted),
              Gap.w8,
              Text(label,
                  style: AppType.mono(
                    size: 14,
                    weight: FontWeight.w700,
                    color: active ? AppColors.signal : AppColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParamSlider extends StatelessWidget {
  const _ParamSlider({
    required this.label,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int value;
  final int min;
  final int max;
  final String unit;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Gap.w8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.baseBg,
                borderRadius: Radii.chip,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(hint,
                  style: AppType.mono(size: 10, color: AppColors.textMuted)),
            ),
            const Spacer(),
            Text('$value$unit',
                style: AppType.mono(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.signal)),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: enabled ? (v) => onChanged(v.round()) : null,
        ),
      ],
    );
  }
}
