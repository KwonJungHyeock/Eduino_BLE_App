// Author: eduino
// 교구 제어판 — 선택한 킷의 능력(ControlSpec)에 따라 컨트롤 위젯을 자동 구성.
// RC카·스마트팩토리·홈·팜을 같은 화면 로직으로 흡수한다(플랫폼화).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../providers/kit_providers.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/surface_card.dart';
import '../kit/kit_profile.dart';

class ControlPanelScreen extends ConsumerStatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  ConsumerState<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends ConsumerState<ControlPanelScreen> {
  final Map<String, bool> _toggles = {};
  final Map<String, double> _sliders = {};
  final TextEditingController _lcd = TextEditingController();

  String _k(ControlSpec s) => '${s.kind}_${s.id}_${s.label}';

  @override
  void dispose() {
    _lcd.dispose();
    super.dispose();
  }

  CarController get _car => ref.read(carControllerProvider);

  @override
  Widget build(BuildContext context) {
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final connected = ref.watch(connectionProvider).isConnected;

    return Scaffold(
      appBar: AppBar(title: Text(kit?.name ?? '교구 제어')),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: kit == null
                ? _needKit(context)
                : ListView(
                    padding: const EdgeInsets.all(Gap.md),
                    children: [
                      for (final spec in kit.controls) ...[
                        _buildControl(spec, connected),
                        Gap.h12,
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _needKit(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_outlined,
                size: 44, color: AppColors.textMuted),
            Gap.h16,
            Text('먼저 교구를 선택하세요.',
                style: AppType.mono(size: 13, color: AppColors.textMuted)),
            Gap.h16,
            FilledButton(
                onPressed: () => context.push(Routes.kit),
                child: const Text('교구 선택')),
          ],
        ),
      );

  Widget _buildControl(ControlSpec s, bool connected) {
    switch (s.kind) {
      case ControlKind.drive:
        return _DriveCard(spec: s);
      case ControlKind.ledToggle:
        return _ToggleCard(
          spec: s,
          value: _toggles[_k(s)] ?? false,
          enabled: connected,
          onChanged: (v) {
            setState(() => _toggles[_k(s)] = v);
            _car.ledOnOff(v);
          },
        );
      case ControlKind.relayToggle:
        return _ToggleCard(
          spec: s,
          value: _toggles[_k(s)] ?? false,
          enabled: connected,
          onChanged: (v) {
            setState(() => _toggles[_k(s)] = v);
            _car.setActuator(s.id, v);
          },
        );
      case ControlKind.pwmSlider:
        return _SliderCard(
          spec: s,
          value: _sliders[_k(s)] ?? s.min.toDouble(),
          enabled: connected,
          onChanged: (v) {
            setState(() => _sliders[_k(s)] = v);
            _car.setActuatorPwm(s.id, v.round());
          },
        );
      case ControlKind.servoSlider:
        return _SliderCard(
          spec: s,
          value: _sliders[_k(s)] ?? s.min.toDouble(),
          enabled: connected,
          onChanged: (v) {
            setState(() => _sliders[_k(s)] = v);
            _car.setServo(s.id, v.round());
          },
        );
      case ControlKind.lcdText:
        return _LcdCard(
          spec: s,
          controller: _lcd,
          enabled: connected,
          onSend: () {
            final t = _lcd.text.trim();
            if (t.isEmpty) return;
            HapticFeedback.selectionClick();
            _car.sendLcd(0, t);
          },
        );
      case ControlKind.sensorReadout:
        return _SensorCard(spec: s);
    }
  }
}

class _DriveCard extends StatelessWidget {
  const _DriveCard({required this.spec});
  final ControlSpec spec;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(Routes.controller),
      borderRadius: Radii.card,
      child: SurfaceCard(
        child: Row(
          children: [
            _iconBox(spec.icon, AppColors.signal),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('조이스틱 · 방향 · 기울기 · 음성',
                      style:
                          AppType.mono(size: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.spec,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final ControlSpec spec;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          _iconBox(spec.icon, value ? AppColors.signal : AppColors.textMuted),
          Gap.w16,
          Expanded(
            child: Text(spec.label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.spec,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final ControlSpec spec;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(spec.icon, AppColors.signal),
              Gap.w16,
              Expanded(
                child: Text(spec.label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Text('${value.round()}${spec.unit}',
                  style: AppType.mono(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.signal)),
            ],
          ),
          Slider(
            value: value.clamp(spec.min.toDouble(), spec.max.toDouble()).toDouble(),
            min: spec.min.toDouble(),
            max: spec.max.toDouble(),
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _LcdCard extends StatelessWidget {
  const _LcdCard({
    required this.spec,
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final ControlSpec spec;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(spec.icon, AppColors.signal),
              Gap.w16,
              Text(spec.label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          Gap.h12,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: AppType.mono(size: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'LCD에 표시할 문자',
                    hintStyle:
                        AppType.mono(size: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceHigh,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: Gap.md, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: Radii.chip,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: Radii.chip,
                      borderSide: const BorderSide(color: AppColors.signal),
                    ),
                  ),
                ),
              ),
              Gap.w8,
              FilledButton(
                onPressed: enabled ? onSend : null,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 48)),
                child: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends ConsumerWidget {
  const _SensorCard({required this.spec});
  final ControlSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tele = ref.watch(telemetryProvider);
    String value;
    if (spec.sensorKey == 'DST') {
      value = tele.distanceCm?.toString() ?? '--';
    } else {
      final v = tele.sensors[spec.sensorKey];
      value = v == null
          ? '--'
          : (v == v.roundToDouble()
              ? v.toInt().toString()
              : v.toStringAsFixed(1));
    }
    return SurfaceCard(
      child: Row(
        children: [
          _iconBox(spec.icon, AppColors.signalDeep),
          Gap.w16,
          Expanded(
            child: Text(spec.label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          Text('$value${value == '--' ? '' : spec.unit}',
              style: AppType.instrument(size: 30, color: AppColors.signalDeep)),
        ],
      ),
    );
  }
}

Widget _iconBox(IconData icon, Color color) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.baseBg,
        borderRadius: Radii.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: color, size: 22),
    );
