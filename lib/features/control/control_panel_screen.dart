// Author: eduino
// 교구 통합 제어판 — 선택한 스마트킷의 commandMap(데이터)으로 컨트롤/모니터를 자동 렌더.
// [제어] 토글·색상 / [모니터링] 온습도·토양. 명령은 kit_controls 데이터에서만 온다(하드코딩 금지).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../providers/kit_providers.dart';
import '../../widgets/circuit.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/kit_illustration.dart';
import '../../widgets/responsive.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/surface_card.dart';
import '../kit/kit_controls.dart';
import '../kit/kit_profile.dart';

class ControlPanelScreen extends ConsumerStatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  ConsumerState<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends ConsumerState<ControlPanelScreen> {
  final Map<String, bool> _toggles = {};
  String? _lastSent; // "전송 → x" (보이는 통신)
  Timer? _monitorTimer;
  KitType? _wiredType;

  CarController get _car => ref.read(carControllerProvider);

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  /// 홈 온습도처럼 주기 요청이 필요한 킷이면 타이머 구동(전송은 연결 가드).
  void _wireMonitor(KitType type, KitControlSet set) {
    if (_wiredType == type) return; // 이미 배선됨.
    _wiredType = type;
    _monitorTimer?.cancel();
    final req = set.monitorRequest;
    if (req != null) {
      _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _car.kitRequest(req, log: '온습도 요청(0x00)');
      });
    }
  }

  void _send(String display, VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
    setState(() => _lastSent = display);
  }

  @override
  Widget build(BuildContext context) {
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final connected = ref.watch(connectionProvider).isConnected;
    final set = kit == null ? null : kitControlsFor(kit.type);
    if (kit != null && set != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _wireMonitor(kit.type, set));
    }

    return Scaffold(
      appBar: AppBar(title: Text(kit?.name ?? '교구 제어')),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: (kit == null || set == null)
                ? _needKit(context)
                : ListView(
                    padding: pagePadding(context),
                    children: [
                      _KitHeader(kit: kit),
                      Gap.h16,
                      if (!connected) ...[
                        ConnectCtaBanner(
                          accent: AppColors.accent,
                          onConnect: () => context.push(Routes.connect),
                        ),
                        Gap.h16,
                      ],
                      // 보이는 통신 — 마지막 전송값.
                      _SentChip(text: _lastSent),
                      Gap.h16,
                      const NodeRailHeader('제어', color: AppColors.accent),
                      Gap.h8,
                      for (final c in set.controls) ...[
                        _control(c, connected),
                        Gap.h12,
                      ],
                      if (set.monitors.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const NodeRailHeader('모니터링',
                            color: AppColors.mint),
                        Gap.h8,
                        for (final m in set.monitors) ...[
                          _MonitorCard(monitor: m),
                          Gap.h12,
                        ],
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
        message: '스마트 팩토리 · 홈 · 팜 중에서\n보유한 교구를 고르면 딱 맞는 제어판이 열려요.',
        actionLabel: '교구 선택',
        onAction: () => context.push(Routes.kit),
      );

  Widget _control(KitControl c, bool connected) {
    switch (c.kind) {
      case KitCtlKind.toggle:
        return _ToggleCard(
          control: c,
          value: _toggles[c.label] ?? false,
          enabled: connected,
          onChanged: (v) {
            final ch = v ? c.onChar! : c.offChar!;
            setState(() => _toggles[c.label] = v);
            _send(ch, () => _car.kitChar(ch));
          },
        );
      case KitCtlKind.colorPreset:
        return _ColorCard(
          control: c,
          enabled: connected,
          onSwatch: (s) => _send(s.char!, () => _car.kitChar(s.char!)),
          onOff: () => _send(c.offChar!, () => _car.kitChar(c.offChar!)),
        );
      case KitCtlKind.colorRgb:
        return _ColorCard(
          control: c,
          enabled: connected,
          onSwatch: (s) {
            final col = s.color;
            _send('${_r(col)},${_g(col)},${_b(col)}',
                () => _car.kitRgb(_r(col), _g(col), _b(col)));
          },
          onOff: () => _send('0,0,0', () => _car.kitRgb(0, 0, 0)),
        );
    }
  }

  static int _r(Color c) => (c.r * 255).round();
  static int _g(Color c) => (c.g * 255).round();
  static int _b(Color c) => (c.b * 255).round();
}

/// 마지막 전송 표시(보이는 통신) — "전송 → x".
class _SentChip extends StatelessWidget {
  const _SentChip({required this.text});
  final String? text;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tintOf(AppColors.accent),
        borderRadius: Radii.pill,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.north_east, size: 16, color: AppColors.accent),
          Gap.w8,
          Text('전송 → ',
              style: AppType.mono(size: 13, color: AppColors.listTitle)),
          Text(text ?? '—',
              style: AppType.mono(
                  size: 16, weight: FontWeight.w800, color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.control,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final KitControl control;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = value;
    final sub = '${control.onChar} / ${control.offChar}'
        '${control.longPress ? '  ·  길게 눌러 전환' : ''}';
    // 침입자 경보 등 longPress: 스위치 대신 길게 눌러 전환하는 버튼.
    final Widget trailing = control.longPress
        ? GestureDetector(
            onLongPress: enabled ? () => onChanged(!on) : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: on ? AppColors.accent : AppColors.chipGray,
                borderRadius: Radii.pill,
              ),
              child: Text(on ? 'ON' : 'OFF',
                  style: AppType.mono(
                      size: 13,
                      weight: FontWeight.w800,
                      color: on ? Colors.white : AppColors.chipGrayIcon)),
            ),
          )
        : Switch(value: on, onChanged: enabled ? onChanged : null);

    return SurfaceCard(
      child: Row(
        children: [
          _iconBox(control.icon, on ? AppColors.accent : AppColors.chipGrayIcon),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(control.label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub,
                    style: AppType.mono(size: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({
    required this.control,
    required this.enabled,
    required this.onSwatch,
    required this.onOff,
  });
  final KitControl control;
  final bool enabled;
  final void Function(KitSwatch) onSwatch;
  final VoidCallback onOff;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(control.icon, AppColors.accent),
              Gap.w16,
              Text(control.label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          Gap.h12,
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in control.swatches)
                  _swatch(
                    color: s.color,
                    label: s.char ?? '', // 프리셋이면 문자 표시
                    onTap: enabled ? () => onSwatch(s) : null,
                  ),
                _swatch(
                  color: AppColors.surface,
                  label: '×',
                  border: true,
                  onTap: enabled ? onOff : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch({
    required Color color,
    required String label,
    bool border = false,
    VoidCallback? onTap,
  }) {
    final light = color.computeLuminance() > 0.6;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: Radii.chip,
          border: Border.all(
              color: border ? AppColors.border : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Text(label,
            style: AppType.mono(
                size: 12,
                weight: FontWeight.w800,
                color: light ? AppColors.textPrimary : Colors.white)),
      ),
    );
  }
}

class _MonitorCard extends ConsumerWidget {
  const _MonitorCard({required this.monitor});
  final KitMonitor monitor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tele = ref.watch(telemetryProvider);
    final color = monitorColor(monitor.kind);

    String value;
    String extra = '';
    switch (monitor.kind) {
      case KitMonKind.tempHumi:
        final t = tele.sensors['TMP'];
        final h = tele.sensors['HUM'];
        value = t == null ? '--' : '${_fmt(t)}℃';
        extra = h == null ? '' : '습도 ${_fmt(h)}%';
        break;
      case KitMonKind.soil:
        final s = tele.sensors['SOL'];
        value = s == null ? '--' : '${_fmt(s)}%';
        extra = s == null ? '' : '${soilStage(s)}단계';
        break;
    }

    return SurfaceCard(
      child: Row(
        children: [
          _iconBox(monitor.icon, color),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monitor.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (extra.isNotEmpty)
                  Text(extra,
                      style:
                          AppType.mono(size: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(value, style: AppType.instrument(size: 28, color: color)),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// 제어판 상단 헤더 — 선택한 교구 일러스트 + 이름/태그라인.
class _KitHeader extends StatelessWidget {
  const _KitHeader({required this.kit});
  final KitProfile kit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardLg,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: Shadows.soft,
      ),
      child: Row(
        children: [
          KitIllustration(art: kitArtFor(kit.type), size: 68),
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
              ],
            ),
          ),
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
