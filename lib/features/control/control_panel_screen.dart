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

// ── 튜닝 상수(단일 출처) — 매직넘버 제거. 동작 값은 기존과 동일 ──
const Duration _kMonitorPollInterval = Duration(seconds: 2); // 온습도 요청 주기
const int _kFactoryToggleDebounceMs = 350; // 가동/중지 연타 무시 간격
// 센서 임계(코치 카드·상태 칩 공용)
const double _kSoilDry = 30; // 미만 = 건조
const double _kSoilWet = 70; // 초과 = 과습
const double _kTempHot = 30; // 초과 = 더움(냉각 권장)
const double _kHumiHigh = 85; // 초과 = 과습(환기 권장)

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
  bool _factorySynced = false; // 팩토리: 연결당 's' 상태질의 1회.
  int _lastFactoryToggleMs = 0; // 팩토리 가동/중지 연타 디바운스.

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
      _monitorTimer = Timer.periodic(_kMonitorPollInterval, (_) {
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
      // 보드 y/n 회신을 우선 반영(없으면 마지막 토글 상태).
      running: tele.factoryRunning ?? (_toggles['컨베이어 가동 / 중지'] ?? false),
      live: connected,
      sortCounts: tele.sortCounts,
      lastSort: tele.lastSort,
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

    // A-1 · 팩토리 가동 표시는 수신 y/n(factoryRunning) 기준으로 갱신 —
    // 토글 스위치를 보드 실제 상태에 맞춰 동기화(중지 눌러도 남는 문제 방지).
    ref.listen<bool?>(telemetryProvider.select((t) => t.factoryRunning),
        (prev, next) {
      if (isFactory &&
          next != null &&
          (_toggles['컨베이어 가동 / 중지'] ?? false) != next) {
        setState(() => _toggles['컨베이어 가동 / 중지'] = next);
      }
    });
    // A-1 · 진입/재연결 시 상태질의 문자(kit_controls 의 initChar='s')로 동기화(연결당 1회).
    final factoryInit = set?.initChar;
    if (connected && isFactory && factoryInit != null && !_factorySynced) {
      _factorySynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _car.kitChar(factoryInit);
      });
    }
    if (!connected) _factorySynced = false;

    return Scaffold(
      appBar: AppBar(title: Text(kit?.name ?? '교구 제어')),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: (kit == null || set == null)
                ? _needKit(context)
                : ListView(
                    // B-3 · 마지막 카드가 잘리지 않게 하단 스크롤 여백 확보.
                    padding: pagePadding(context).copyWith(bottom: 40),
                    children: [
                      _KitHeader(kit: kit),
                      Gap.h16,
                      // Living Twin — 씬 + (미연결 시) 씬 바로 아래 연결 CTA 1곳 통일(C-2).
                      if (isFarm) ...[
                        LivingGreenhouse(state: gh),
                        Gap.h12,
                        if (!connected) ...[
                          ConnectCtaBanner(
                            accent: AppColors.accent,
                            onConnect: () => context.push(Routes.connect),
                          ),
                          Gap.h12,
                        ],
                        if (gh.hasData) ...[
                          _CoachCard(state: gh),
                          Gap.h12,
                        ],
                        // 모니터링(토양수분·온·습도)을 씬 바로 아래에 통합.
                        for (final m in set.monitors) ...[
                          _MonitorCard(monitor: m),
                          Gap.h12,
                        ],
                        Gap.h4,
                      ],
                      if (isHome) ...[
                        LivingHouse(state: house),
                        Gap.h12,
                        if (!connected) ...[
                          ConnectCtaBanner(
                            accent: AppColors.accent,
                            onConnect: () => context.push(Routes.connect),
                          ),
                          Gap.h12,
                        ],
                        Gap.h4,
                      ],
                      if (isFactory) ...[
                        LivingFactory(state: factory),
                        Gap.h12,
                        if (!connected) ...[
                          ConnectCtaBanner(
                            accent: AppColors.accent,
                            onConnect: () => context.push(Routes.connect),
                          ),
                          Gap.h12,
                        ],
                        _FactorySortCard(state: factory),
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
                      // 홈=집 씬 벽 온도계 / 팜=씬 바로 아래 통합 → 하단 별도 패널 생략.
                      if (set.monitors.isNotEmpty && !isHome && !isFarm) ...[
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
            // A-1 · 팩토리 가동/중지 연타 디바운스(상태 어긋남 방지).
            if (c.label == '컨베이어 가동 / 중지') {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - _lastFactoryToggleMs < _kFactoryToggleDebounceMs) return;
              _lastFactoryToggleMs = now;
            }
            // 경보(armed) 켜기 = warning급 햅틱(C4), 그 외 토글=light.
            if (c.longPress && v) HapticFeedback.heavyImpact();
            setState(() => _toggles[c.label] = v);
            // 팜 통합 펌웨어는 텍스트 라인(FAN:1/0), 나머지는 단일문자.
            final line = v ? c.onLine : c.offLine;
            if (line != null) {
              _send(line, () => _car.kitLine(line));
            } else {
              final ch = v ? c.onChar! : c.offChar!;
              _send(ch, () => _car.kitChar(ch));
            }
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
          onSwatch: (s) => _pickColor(c, s.color),
          onColor: (col) => _pickColor(c, col),
          onOff: () {
            setState(() => _ledColor = null);
            final prefix = c.rgbLinePrefix;
            if (prefix != null) {
              final line = '$prefix:0,0,0';
              _send(line, () => _car.kitLine(line));
            } else {
              _send('0,0,0', () => _car.kitRgb(0, 0, 0));
            }
          },
        );
    }
  }

  /// 팜 네오픽셀 — 임의 색 → 'LED:r,g,b' 텍스트 라인 전송(통합 펌웨어 · QA 0-1) + 조명 틴트.
  void _pickColor(KitControl c, Color col) {
    setState(() => _ledColor = col);
    final prefix = c.rgbLinePrefix;
    if (prefix != null) {
      final line = '$prefix:${_r(col)},${_g(col)},${_b(col)}';
      _send(line, () => _car.kitLine(line));
    } else {
      _send('${_r(col)},${_g(col)},${_b(col)}',
          () => _car.kitRgb(_r(col), _g(col), _b(col)));
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

/// 스마트 팩토리 색 분류 결과(QA 0-3) — 보드가 보낸 r/g/b 를 색별 집계.
class _FactorySortCard extends StatelessWidget {
  const _FactorySortCard({required this.state});
  final FactoryState state;

  static const _cols = {
    'r': Color(0xFFE53935),
    'g': Color(0xFF43A047),
    'b': Color(0xFF1E88E5),
  };
  static const _names = {'r': '빨강', 'g': '초록', 'b': '파랑'};

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.category_outlined, AppColors.signal),
              Gap.w16,
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('색 분류 결과',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('보드가 분류한 실제 개수',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.listDesc)),
                  ],
                ),
              ),
              Text('합계 ${state.total}',
                  style: AppType.mono(
                      size: 14,
                      weight: FontWeight.w800,
                      color: AppColors.listTitle)),
            ],
          ),
          Gap.h12,
          Row(
            children: [
              for (final k in const ['r', 'g', 'b']) ...[
                Expanded(child: _countChip(k, state.sortCounts[k] ?? 0)),
                if (k != 'b') Gap.w8,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip(String k, int n) {
    final col = _cols[k]!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.10),
        borderRadius: Radii.chip,
        border: Border.all(color: col.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(_names[k]!,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$n',
              style: AppType.instrument(size: 26, color: col)),
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
    if (g.soil != null && g.soil! < _kSoilDry) {
      return (msg: '흙이 많이 말랐어요 — 물을 주거나 습도를 높여 주세요.', icon: Icons.water_drop, warn: true);
    }
    if (g.temp != null && g.temp! > _kTempHot && !g.fanOn) {
      return (msg: '온실이 더워요 — 냉각팬을 켜 보세요.', icon: Icons.thermostat, warn: true);
    }
    if (g.humi != null && g.humi! > _kHumiHigh) {
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
    // 전송 명령 표시 — 텍스트 라인(FAN:1/0)이면 그것을, 아니면 단일문자.
    final onLbl = control.onLine ?? control.onChar ?? '';
    final offLbl = control.offLine ?? control.offChar ?? '';
    final sub = '$onLbl / $offLbl'
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

    final isTH = widget.monitor.kind == KitMonKind.tempHumi;
    final soil = tele.sensors['SOL'];

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(widget.monitor.icon, color),
              Gap.w16,
              Text(widget.monitor.label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          Gap.h12,
          if (isTH)
            // B-2 · 온도·습도를 나란히 같은 크기로 크게(라벨 12px).
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _bigStat(
                      '온도',
                      tele.sensors['TMP'] == null
                          ? '--'
                          : '${_fmt(tele.sensors['TMP']!)}℃',
                      color),
                ),
                Gap.w16,
                Expanded(
                  child: _bigStat(
                      '습도',
                      tele.sensors['HUM'] == null
                          ? '--'
                          : '${_fmt(tele.sensors['HUM']!)}%',
                      AppColors.signal),
                ),
              ],
            )
          else
            // B-1 · 토양수분 실제 %(임의 단계 제거) + 상태 라벨(건조<30·적정·과습>70).
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _bigStat('토양수분',
                      soil == null ? '--' : '${_fmt(soil)}%', color),
                ),
                if (soil != null) _soilStatusChip(soil),
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

  // 큰 수치 블록(라벨 12px + 값 인스트루먼트 30px, 좁은 폭 축소).
  Widget _bigStat(String label, String value, Color c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppType.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.textMuted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child:
                Text(value, style: AppType.instrument(size: 30, color: c)),
          ),
        ],
      );

  // 토양수분 상태 라벨 — 건조<30 / 적정 / 과습>70.
  Widget _soilStatusChip(double s) {
    final (label, c) = s < _kSoilDry
        ? ('건조', AppColors.warn)
        : s > _kSoilWet
            ? ('과습', AppColors.signal)
            : ('적정', AppColors.mint);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: Radii.pill,
      ),
      child: Text(label,
          style:
              AppType.mono(size: 12, weight: FontWeight.w800, color: c)),
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
