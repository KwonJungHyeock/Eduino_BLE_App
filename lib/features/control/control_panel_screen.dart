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
import '../../widgets/empty_state.dart';
import '../../widgets/kit_illustration.dart';
import '../../widgets/responsive.dart';
import '../../widgets/sparkline.dart';
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
                    padding: pagePadding(context),
                    children: [
                      _KitHeader(kit: kit),
                      Gap.h16,
                      if (!connected) ...[
                        DisconnectedBanner(
                            onTap: () => context.push(Routes.connect)),
                        Gap.h16,
                      ],
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

  Widget _needKit(BuildContext context) => EmptyState(
        icon: Icons.smart_toy_outlined,
        accent: AppColors.accent,
        title: '먼저 내 교구를 선택하세요',
        message: 'RC카 · 스마트 팩토리 · 홈 · 팜 중에서\n보유한 교구를 고르면 딱 맞는 제어판이 열려요.',
        actionLabel: '교구 선택',
        onAction: () => context.push(Routes.kit),
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

/// 제어판 상단 헤더 — 선택한 교구의 커스텀 일러스트 + 이름/태그라인.
class _KitHeader extends StatelessWidget {
  const _KitHeader({required this.kit});
  final KitProfile kit;

  @override
  Widget build(BuildContext context) {
    final accent = kit.isRc ? AppColors.accent : AppColors.signal;
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardLg,
        border: Border.all(color: AppColors.border),
        boxShadow: Shadows.soft,
      ),
      child: Row(
        children: [
          KitIllustration(art: kitArtFor(kit.type), size: 76),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kit.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Gap.h4,
                Text(kit.tagline,
                    style: AppType.mono(
                        size: 11, color: AppColors.textMuted, height: 1.4)),
                Gap.h8,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: Radii.pill,
                  ),
                  child: Text(
                    kit.isRc ? 'RC카 제어' : '스마트 교구',
                    style: AppType.mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 센서 카드 — 대형 수치 + 최근 추이 스파크라인(데이터 시각화).
class _SensorCard extends ConsumerStatefulWidget {
  const _SensorCard({required this.spec});
  final ControlSpec spec;

  @override
  ConsumerState<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends ConsumerState<_SensorCard> {
  final List<double> _hist = [];

  double? _extract(TelemetryState t) {
    if (widget.spec.sensorKey == 'DST') return t.distanceCm?.toDouble();
    return t.sensors[widget.spec.sensorKey];
  }

  Color get _color => switch (widget.spec.sensorKey) {
        'DST' => AppColors.signal,
        'TMP' => AppColors.accent,
        'HUM' => AppColors.signalDeep,
        'LUX' => AppColors.sun,
        'SOL' => AppColors.mint,
        _ => AppColors.signalDeep,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(telemetryProvider, (prev, next) {
      final v = _extract(next);
      if (v != null && (_hist.isEmpty || _hist.last != v)) {
        setState(() {
          _hist.add(v);
          if (_hist.length > 40) _hist.removeAt(0);
        });
      }
    });

    final tele = ref.watch(telemetryProvider);
    final cur = _extract(tele);
    final value = cur == null
        ? '--'
        : (cur == cur.roundToDouble()
            ? cur.toInt().toString()
            : cur.toStringAsFixed(1));

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(widget.spec.icon, _color),
              Gap.w16,
              Expanded(
                child: Text(widget.spec.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text('$value${value == '--' ? '' : widget.spec.unit}',
                  style: AppType.instrument(size: 30, color: _color)),
            ],
          ),
          Gap.h12,
          Sparkline(values: _hist, color: _color, height: 38),
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
