// Author: eduino
// 라인트레이싱 모드 — IR 라인센서(2휠 2개 / 4휠 3개)로 검은 선을 따라 자율 주행.
// 시작/정지 + 라이브 센서 표시 + 민감도(LINE)·속도(SPD) 튜닝. "값을 바꾸면 행동이 바뀐다".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../providers/rc_config_providers.dart';
import '../../widgets/line_sensor_indicator.dart';
import '../../widgets/surface_card.dart';

class LineTraceScreen extends ConsumerStatefulWidget {
  const LineTraceScreen({super.key});

  @override
  ConsumerState<LineTraceScreen> createState() => _LineTraceScreenState();
}

class _LineTraceScreenState extends ConsumerState<LineTraceScreen> {
  int _lineSens = 50;
  int _speed = 60;
  bool _running = false;

  void _setRunning(bool run) {
    HapticFeedback.mediumImpact();
    setState(() => _running = run);
    ref
        .read(carControllerProvider)
        .setMode(run ? DriveMode.line : DriveMode.manual);
  }

  void _setParam(PrmKey key, int value) =>
      ref.read(carControllerProvider).setParam(key, value);

  @override
  Widget build(BuildContext context) {
    final rc = ref.watch(rcConfigProvider).valueOrNull ?? const RcConfig();
    final tele = ref.watch(telemetryProvider);
    final connected = ref.watch(connectionProvider).isConnected;
    final count = rc.lineSensorCount;
    final isLine = _running || tele.mode == DriveMode.line;

    if (count == 0) {
      // 라인센서가 없는 설정(메탈 등) — 안내 + 설정 이동.
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.signal.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.linear_scale,
                      size: 40, color: AppColors.signal),
                ),
                Gap.h24,
                const Text('라인센서가 꺼져 있어요',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Gap.h8,
                Text(
                  '라인트레이싱은 IR 라인센서가 필요해요.\n컨트롤러 설정에서 라인센서를 켜주세요.',
                  textAlign: TextAlign.center,
                  style: AppType.mono(
                      size: 12, color: AppColors.textMuted, height: 1.5),
                ),
                Gap.h24,
                FilledButton.icon(
                  onPressed: () => context.push(Routes.rcConfig),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('컨트롤러 설정 열기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          _StartStop(
            running: isLine,
            enabled: connected,
            onChanged: _setRunning,
          ),
          Gap.h16,
          if (!isLine)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.route, color: AppColors.signal),
                      SizedBox(width: Gap.sm),
                      Text('라인트레이싱이란?',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Gap.h8,
                  Text(
                    '바닥의 검은 선을 IR 센서($count개)로 읽어 선을 따라 달립니다.\n'
                    '① "시작"을 누르면 라인트레이싱(MOD:LINE)이 켜집니다.\n'
                    '② 아래 슬라이더로 민감도·속도를 바꾸면\n'
                    '   코드 재업로드 없이 주행이 즉시 달라져요.',
                    style: AppType.mono(
                        size: 12, color: AppColors.textMuted, height: 1.7),
                  ),
                ],
              ),
            )
          else ...[
            Text('라이브 라인센서',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            SurfaceCard(
              child: LineSensorIndicator(line: tele.line, count: count),
            ),
            Gap.h24,
            Text('실시간 파라미터 튜닝 (PRM)',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            SurfaceCard(
              child: Column(
                children: [
                  _ParamSlider(
                    label: '라인 민감도',
                    hint: 'LINE',
                    value: _lineSens,
                    min: 0,
                    max: 100,
                    unit: '',
                    enabled: connected,
                    onChanged: (v) {
                      setState(() => _lineSens = v);
                      _setParam(PrmKey.line, v);
                    },
                  ),
                  const Divider(height: Gap.lg),
                  _ParamSlider(
                    label: '주행 속도',
                    hint: 'SPD',
                    value: _speed,
                    min: 0,
                    max: 100,
                    unit: '',
                    enabled: connected,
                    onChanged: (v) {
                      setState(() => _speed = v);
                      _setParam(PrmKey.spd, v);
                    },
                  ),
                ],
              ),
            ),
          ],
          if (!connected) ...[
            Gap.h16,
            Text('연결 후 실제 전송됩니다.',
                style: AppType.mono(size: 11, color: AppColors.warn)),
          ],
        ],
      ),
    );
  }
}

class _StartStop extends StatelessWidget {
  const _StartStop({
    required this.running,
    required this.enabled,
    required this.onChanged,
  });
  final bool running;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = running ? AppColors.accent : AppColors.signal;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? () => onChanged(!running) : null,
        borderRadius: Radii.pill,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: c,
            borderRadius: Radii.pill,
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(running ? Icons.stop : Icons.play_arrow,
                  color: Colors.white, size: 26),
              Gap.w8,
              Text(running ? '정지' : '라인트레이싱 시작',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
          value:
              value.toDouble().clamp(min.toDouble(), max.toDouble()).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: enabled ? (v) => onChanged(v.round()) : null,
        ),
      ],
    );
  }
}
