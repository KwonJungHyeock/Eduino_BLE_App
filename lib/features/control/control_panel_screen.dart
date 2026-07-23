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
import '../../widgets/pressable.dart';
import '../../widgets/responsive.dart';
import '../../widgets/sparkline.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/surface_card.dart';
import '../kit/kit_controls.dart';
import '../kit/kit_profile.dart';
import 'living_factory.dart';
import 'living_greenhouse.dart';
import 'living_house.dart';

class ControlPanelScreen extends ConsumerStatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  ConsumerState<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends ConsumerState<ControlPanelScreen> {
  final Map<String, bool> _toggles = {};
  String? _lastSent; // "전송 → x" (보이는 통신)
  Color? _ledColor; // Living Twin 조명 틴트(마지막 선택 색).
  Timer? _monitorTimer;
  KitType? _wiredType;
  bool _demoSeeded = false; // 팜 데모: 팬/LED 기본값 1회 시드.

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
    final tele = ref.watch(telemetryProvider);
    final set = kit == null ? null : kitControlsFor(kit.type);
    // Living Twin 상태(현재는 팜 씬). 홈/팩토리 확장 지점.
    final gh = GreenhouseState(
      soil: tele.sensors['SOL'],
      temp: tele.sensors['TMP'],
      humi: tele.sensors['HUM'],
      fanOn: _toggles['냉각팬'] ?? false,
      ledColor: _ledColor,
      live: connected,
    );
    final isFarm = kit?.type == KitType.smartFarm;
    final isHome = kit?.type == KitType.smartHome;
    final isFactory = kit?.type == KitType.smartFactory;
    final factory = FactoryState(
      running: _toggles['컨베이어 가동 / 중지'] ?? false,
      live: connected,
    );
    // Living Twin 집 씬 상태(홈).
    final house = HouseState(
      temp: tele.sensors['TMP'],
      humi: tele.sensors['HUM'],
      acOn: _toggles['에어컨'] ?? false,
      doorOpen: _toggles['현관문'] ?? false,
      alarmOn: _toggles['침입자 경보'] ?? false,
      ledColor: _ledColor,
      live: connected,
    );
    if (kit != null && set != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _wireMonitor(kit.type, set));
    }
    // 데모(웹): 연결되면 액추에이터 기본값을 시드해 히어로가 완전히 살아나게 한다.
    final demoFarm = ref.watch(demoFarmProvider).valueOrNull ?? false;
    final demoHome = ref.watch(demoHomeProvider).valueOrNull;
    final demoFactory = ref.watch(demoFactoryProvider).valueOrNull ?? false;
    if (connected && !_demoSeeded) {
      if (isFactory && demoFactory) {
        _demoSeeded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _toggles['컨베이어 가동 / 중지'] = true);
        });
      } else if (isFarm && demoFarm) {
        _demoSeeded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _toggles['냉각팬'] = true;
            _ledColor = const Color(0xFFB56BFF); // 보라 그로우라이트 틴트.
          });
        });
      } else if (isHome && demoHome != null) {
        _demoSeeded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            if (demoHome == 'alarm') {
              _toggles['침입자 경보'] = true;
            } else {
              _toggles['에어컨'] = true;
              _toggles['현관문'] = true;
              _ledColor = const Color(0xFFB56BFF); // 보라 무드라이트(앰비언트 가시성).
            }
          });
        });
      }
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
                      // Living Twin — 살아있는 온실 씬. 코칭은 실제 센서값이
                      // 있을 때만(B1 · 미연결 안내는 씬 오버레이 + 연결 CTA 로 일원화).
                      if (isFarm) ...[
                        LivingGreenhouse(state: gh),
                        if (gh.hasData) ...[
                          Gap.h12,
                          _CoachCard(state: gh),
                        ],
                        Gap.h16,
                      ],
                      // Living Twin — 살아있는 집 씬(홈).
                      if (isHome) ...[
                        LivingHouse(state: house),
                        Gap.h16,
                      ],
                      // Living Twin — 가동 라인 씬(팩토리).
                      if (isFactory) ...[
                        LivingFactory(state: factory),
                        Gap.h16,
                      ],
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
            // 경보(armed) 켜기 = warning급 햅틱(C4), 그 외 토글=light.
            if (c.longPress && v) HapticFeedback.heavyImpact();
            setState(() => _toggles[c.label] = v);
            _send(ch, () => _car.kitChar(ch));
          },
        );
      case KitCtlKind.colorPreset:
        return _ColorCard(
          control: c,
          enabled: connected,
          selectedColor: _ledColor,
          onSwatch: (s) {
            setState(() => _ledColor = s.color); // 방 앰비언트 틴트 반영.
            _send(s.char!, () => _car.kitChar(s.char!));
          },
          onOff: () {
            setState(() => _ledColor = null);
            _send(c.offChar!, () => _car.kitChar(c.offChar!));
          },
        );
      case KitCtlKind.colorRgb:
        return _ColorCard(
          control: c,
          enabled: connected,
          spectrum: true, // C1 · 무지개 자유 색(컬러 피커).
          selectedColor: _ledColor,
          onSwatch: (s) => _pickColor(s.color),
          onColor: _pickColor,
          onOff: () {
            setState(() => _ledColor = null);
            _send('0,0,0', () => _car.kitRgb(0, 0, 0));
          },
        );
    }
  }

  /// 팜 네오픽셀 — 임의 색 → R,G,B 3바이트 전송 + 온실 조명 틴트 반영.
  void _pickColor(Color col) {
    setState(() => _ledColor = col);
    _send('${_r(col)},${_g(col)},${_b(col)}',
        () => _car.kitRgb(_r(col), _g(col), _b(col)));
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

/// 상태 코칭 카드(B2) — 임계 기반 안내. 경고 톤(코랄) ↔ 안정 톤(민트).
class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.state});
  final GreenhouseState state;

  ({String msg, IconData icon, bool warn}) _coach() {
    final g = state;
    if (g.soil != null && g.soil! < 30) {
      return (msg: '흙이 많이 말랐어요 — 물을 주거나 습도를 높여 주세요.', icon: Icons.water_drop, warn: true);
    }
    if (g.temp != null && g.temp! > 30 && !g.fanOn) {
      return (msg: '온실이 더워요 — 냉각팬을 켜 보세요.', icon: Icons.thermostat, warn: true);
    }
    if (g.humi != null && g.humi! > 85) {
      return (msg: '습도가 너무 높아요 — 환기가 필요할 수 있어요.', icon: Icons.cloud, warn: true);
    }
    if (g.soil == null && g.temp == null && g.humi == null) {
      return (msg: '연결하면 센서값으로 온실이 살아 움직여요.', icon: Icons.eco, warn: false);
    }
    return (msg: '환경이 안정적이에요. 식물이 건강해요.', icon: Icons.eco, warn: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = _coach();
    final color = c.warn ? AppColors.warn : AppColors.mint;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: Radii.card,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(c.icon, color: color, size: 22),
          Gap.w12,
          Expanded(
            child: Text(c.msg,
                style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.listTitle)),
          ),
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
        : Container(
            decoration: on
                ? BoxDecoration(
                    borderRadius: Radii.pill,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  )
                : null,
            child: Switch(
              value: on,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: AppColors.accent, // 제어 토글=코랄 채움(B2)
            ),
          );

    return SurfaceCard(
      child: Row(
        children: [
          _iconBox(control.icon, AppColors.accent), // 제어=코랄 통일(A4)
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
    this.spectrum = false,
    this.onColor,
    this.selectedColor,
  });
  final KitControl control;
  final bool enabled;
  final void Function(KitSwatch) onSwatch;
  final VoidCallback onOff;
  final bool spectrum; // 무지개 자유 색 피커 노출(팜 네오픽셀).
  final void Function(Color)? onColor;
  final Color? selectedColor; // 현재 선택 색(선택 아웃라인 표시 · B4).

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
          // 무지개 스펙트럼 — 자유 색 선택(C1). 프리셋은 빠른 선택으로 아래 유지.
          if (spectrum && onColor != null) ...[
            Gap.h12,
            _SpectrumBar(
              enabled: enabled,
              onPick: onColor!,
            ),
          ],
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
                    selected: selectedColor != null &&
                        s.color.toARGB32() == selectedColor!.toARGB32(),
                    onTap: enabled ? () => onSwatch(s) : null,
                  ),
                _swatch(
                  color: AppColors.surface,
                  label: '×',
                  border: true,
                  selected: selectedColor == null,
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
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final light = color.computeLuminance() > 0.6;
    return Pressable(
      onTap: onTap ?? () {},
      enabled: onTap != null,
      pressedScale: 0.92, // 스와치 press(B4)
      semanticLabel: border ? '조명 끄기' : '색상 선택',
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: Radii.chip,
          border: Border.all(
            color: selected
                ? Colors.white
                : (border
                    ? AppColors.border
                    : Colors.black.withValues(alpha: 0.06)),
            width: selected ? 3 : 1,
          ),
          boxShadow: selected ? Shadows.lift : null, // 선택 강조(B4)
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

/// 무지개 스펙트럼 바(C1) — 탭/드래그로 임의 색 선택 → HSV(색상,1,1) → RGB 전송.
class _SpectrumBar extends StatefulWidget {
  const _SpectrumBar({required this.enabled, required this.onPick});
  final bool enabled;
  final void Function(Color) onPick;

  @override
  State<_SpectrumBar> createState() => _SpectrumBarState();
}

class _SpectrumBarState extends State<_SpectrumBar> {
  double? _frac; // 0..1 선택 위치(무선택 시 null).

  static const List<Color> _hues = [
    Color(0xFFFF0000),
    Color(0xFFFF8000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFF8000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  void _pick(double dx, double width) {
    if (!widget.enabled) return;
    final f = (dx / width).clamp(0.0, 1.0);
    final color = HSVColor.fromAHSV(1, f * 360, 1, 1).toColor();
    setState(() => _frac = f);
    HapticFeedback.selectionClick();
    widget.onPick(color);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: GestureDetector(
          onTapDown: (d) => _pick(d.localPosition.dx, width),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, width),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: Radii.pill,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06)),
                  gradient: const LinearGradient(colors: _hues),
                ),
              ),
              if (_frac != null)
                Positioned(
                  left: (_frac! * width - 9).clamp(0.0, width - 18),
                  top: 3,
                  child: Container(
                    width: 18,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: Shadows.tap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _MonitorCard extends ConsumerStatefulWidget {
  const _MonitorCard({required this.monitor});
  final KitMonitor monitor;

  @override
  ConsumerState<_MonitorCard> createState() => _MonitorCardState();
}

class _MonitorCardState extends ConsumerState<_MonitorCard> {
  final List<double> _hist = []; // 최근 추이(B3 스파크라인).

  String get _sensorKey =>
      widget.monitor.kind == KitMonKind.soil ? 'SOL' : 'TMP';

  @override
  Widget build(BuildContext context) {
    final color = monitorColor(widget.monitor.kind);
    // 대표값 추이 누적.
    ref.listen(telemetryProvider, (prev, next) {
      final v = next.sensors[_sensorKey];
      if (v != null && (_hist.isEmpty || _hist.last != v)) {
        setState(() {
          _hist.add(v);
          if (_hist.length > 40) _hist.removeAt(0);
        });
      }
    });
    final tele = ref.watch(telemetryProvider);

    String value;
    String extra = '';
    switch (widget.monitor.kind) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(widget.monitor.icon, color),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.monitor.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    if (extra.isNotEmpty)
                      Text(extra,
                          style: AppType.mono(
                              size: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text(value, style: AppType.instrument(size: 28, color: color)),
            ],
          ),
          if (_hist.length >= 2) ...[
            Gap.h12,
            Sparkline(values: _hist, color: color, height: 34),
          ],
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
