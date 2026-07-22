// Author: eduino
// 연결 화면 (§5.1): 권한 → 스캔 → 연결. HM-10(BLE) 주력. HC-06 탭은 현재 스코프 미포함.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/bt/bt_transport.dart';
import '../../providers/bt_providers.dart';
import '../../providers/kit_providers.dart';
import '../../providers/last_device_providers.dart';
import '../../providers/connection_manager.dart';
import '../../providers/module_providers.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/success_check.dart';
import '../../widgets/surface_card.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _permsReady = false;
  bool _requesting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPerms());
  }

  Future<void> _requestPerms() async {
    setState(() => _requesting = true);
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse, // Android 11↓ 스캔용 (§3.3)
      ].request();
      final ok = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final okConnect =
          statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      setState(() {
        _permsReady = ok && okConnect;
        _error = _permsReady ? null : '블루투스 권한이 필요합니다. 설정에서 허용해 주세요.';
      });
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _connect(BtDevice device) async {
    HapticFeedback.selectionClick();
    setState(() => _error = null);
    try {
      await ref.read(transportProvider).connect(device);
      await ref.read(lastDeviceProvider.notifier).save(device); // 재연결용 기억
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = '연결에 실패했어요. RC카/교구 전원과 거리(1~2m)를 확인하고 다시 시도하세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final module = ref.watch(moduleProvider).valueOrNull ?? BtModule.ble;
    final connected = conn.isConnected;

    // 연결되면 성공 연출을 잠깐 보여준 뒤 홈으로 복귀(새로 연결한 경우만).
    ref.listen<BtConnectionState>(connectionProvider, (prev, next) {
      if (prev != BtConnectionState.connected &&
          next == BtConnectionState.connected &&
          mounted) {
        HapticFeedback.mediumImpact();
        // 성공 애니메이션이 보이도록 살짝 지연 후 복귀.
        Future.delayed(const Duration(milliseconds: 1150), () {
          if (!mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.home);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('연결'),
        actions: [
          if (kit != null)
            TextButton.icon(
              onPressed: () => context.push(Routes.kit),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(kit.name, style: AppType.mono(size: 12)),
            ),
          IconButton(
            tooltip: '연결 도움말',
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push(Routes.help),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurfaceCard(
                child: Row(
                  children: [
                    Icon(
                      connected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_searching,
                      color: AppColors.signal,
                    ),
                    Gap.w16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${module.title} 모듈',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Gap.h4,
                          Text(
                              connected
                                  ? '연결되어 있습니다.'
                                  : module == BtModule.spp
                                      ? '설정에서 페어링(PIN 1234) 후 목록에서 선택'
                                      : '전원을 켠 뒤 사용하는 블루투스 모듈을 가까이 두세요.',
                              style: AppType.mono(
                                  size: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    _ConnStateChip(state: conn),
                  ],
                ),
              ),
              if (_error != null) ...[
                Gap.h8,
                Text(_error!,
                    style: AppType.mono(size: 12, color: AppColors.accent)),
              ],
              Gap.h16,
              Expanded(child: _body(conn, module, connected)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (_permsReady && !connected)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(scanResultsProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('다시 스캔',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.signal,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _body(BtConnectionState conn, BtModule module, bool connected) {
    // 이미 연결됨 → 스캔하지 않고(상태 유지) 연결 패널만 표시.
    if (connected) {
      final device = ref.watch(transportProvider).connectedDevice;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessCheck(size: 96),
            Gap.h16,
            Text('연결됨',
                style: AppType.mono(
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.signal)),
            Gap.h8,
            Text(device?.displayName ?? '',
                style: AppType.mono(size: 13, color: AppColors.textMuted)),
            Gap.h24,
            FilledButton(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              child: const Text('완료'),
            ),
            Gap.h8,
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: '연결 해제',
                  message: '블루투스 연결을 해제할까요?\nRC카/교구가 정지합니다.',
                  confirmLabel: '해제',
                  danger: true,
                );
                if (!ok || !context.mounted) return;
                await ref.read(connectionManagerProvider).userDisconnect();
              },
              child: const Text('연결 해제'),
            ),
          ],
        ),
      );
    }
    if (_requesting) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.signal));
    }
    if (!_permsReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled,
                size: 40, color: AppColors.textMuted),
            Gap.h16,
            Text('블루투스 권한이 필요합니다.',
                style: AppType.mono(size: 13, color: AppColors.textMuted)),
            Gap.h4,
            Text('권한을 거부했다면 설정에서 직접 허용해 주세요.',
                textAlign: TextAlign.center,
                style: AppType.mono(size: 11, color: AppColors.textMuted)),
            Gap.h16,
            FilledButton(
                onPressed: _requestPerms, child: const Text('권한 다시 요청')),
            Gap.h8,
            OutlinedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('설정 열기'),
            ),
          ],
        ),
      );
    }
    // 지난 기기(현재 모듈과 동일)면 빠른 재연결 카드 노출.
    final last = ref.watch(lastDeviceProvider).valueOrNull;
    final showReconnect = last != null && last.module == module && !conn.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showReconnect) ...[
          InkWell(
            onTap: () => _connect(last.toDevice()),
            borderRadius: Radii.card,
            child: SurfaceCard(
              color: AppColors.signalTint,
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppColors.signal),
                  Gap.w16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('지난 기기 재연결',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(last.name,
                            style: AppType.mono(
                                size: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.refresh, color: AppColors.signal),
                ],
              ),
            ),
          ),
          Gap.h16,
        ],
        Expanded(
          child: _DeviceList(onConnect: _connect, connecting: conn.isBusy),
        ),
      ],
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.onConnect, required this.connecting});
  final void Function(BtDevice) onConnect;
  final bool connecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanResultsProvider);

    return scan.when(
      loading: () => _hint('스캔 중…', spinner: true),
      error: (e, _) => _hint('스캔 오류: $e'),
      data: (devices) {
        if (devices.isEmpty) return _scanningEmpty();
        return ListView.separated(
          itemCount: devices.length,
          separatorBuilder: (_, __) => Gap.h8,
          itemBuilder: (context, i) {
            final d = devices[i];
            return _DeviceTile(
              device: d,
              enabled: !connecting,
              onTap: () => onConnect(d),
            );
          },
        );
      },
    );
  }

  Widget _scanningEmpty() => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.signal),
              ),
              Gap.h16,
              Text('주변 기기를 찾는 중이에요…',
                  style:
                      AppType.mono(size: 13, color: AppColors.textMuted)),
              Gap.h24,
              Container(
                margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
                padding: const EdgeInsets.all(Gap.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: Radii.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('기기가 안 보이나요?',
                        style: AppType.mono(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Gap.h8,
                    _tip('사용하는 모듈/기기의 전원이 켜져 있는지 확인하세요.'),
                    _tip('HM-10은 연결 전 파란 LED가 깜빡여요.'),
                    _tip('휴대폰과 1~2m 이내로 가까이 두세요.'),
                    _tip('"다시 스캔"을 눌러 목록을 새로고침하세요.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle_outline,
                  size: 15, color: AppColors.signal),
            ),
            Gap.w8,
            Expanded(
              child: Text(text,
                  style: AppType.mono(
                      size: 12, color: AppColors.textMuted, height: 1.4)),
            ),
          ],
        ),
      );

  Widget _hint(String text, {bool spinner = false}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinner) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.signal),
              ),
              Gap.h16,
            ],
            Text(text, style: AppType.mono(size: 13, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.enabled,
    required this.onTap,
  });

  final BtDevice device;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final known = device.isKnownModule;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: enabled ? Shadows.tap : null, // C1: 탭 가능 → 미세 그림자
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tintOf(AppColors.signal),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bluetooth,
                    color: AppColors.signal, size: 20),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(device.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.listTitle)),
                        ),
                        if (known) ...[
                          Gap.w8,
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tintOf(AppColors.signal),
                              borderRadius: Radii.pill,
                            ),
                            child: Text('추천 모듈',
                                style: AppType.mono(
                                    size: 9,
                                    weight: FontWeight.w800,
                                    color: AppColors.signal)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (device.rssi != null) ...[
                          _SignalBars(rssi: device.rssi!),
                          const SizedBox(width: 6),
                          Text('${device.rssi} dBm',
                              style: AppType.mono(
                                  size: 11, color: AppColors.listDesc)),
                          Gap.w8,
                        ],
                        Flexible(
                          child: Text(device.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.mono(
                                  size: 11, color: AppColors.listDesc)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Gap.w8,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  borderRadius: Radii.pill,
                ),
                child: const Text('연결',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 신호세기 막대(초보자 가독성) — RSSI 를 1~4칸으로.
class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.rssi});
  final int rssi;

  @override
  Widget build(BuildContext context) {
    final level = ((rssi + 100) / 12).clamp(1, 4).floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            width: 3,
            height: 5.0 + i * 2.5,
            decoration: BoxDecoration(
              color: i < level ? AppColors.signal : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (i < 3) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _ConnStateChip extends StatelessWidget {
  const _ConnStateChip({required this.state});
  final BtConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (state) {
      BtConnectionState.connected => (AppColors.mint, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔 중'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제 중'),
      BtConnectionState.disconnected => (AppColors.chipGrayIcon, '연결 대기'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.pill,
      ),
      child: Text(text,
          maxLines: 1,
          softWrap: false,
          style: AppType.mono(size: 11, weight: FontWeight.w700, color: color)),
    );
  }
}
