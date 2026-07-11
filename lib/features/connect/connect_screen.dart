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
                                      : '전원이 켜진 RC카를 근처에 두세요.',
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
      floatingActionButton: (_permsReady && !connected)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.surface,
              onPressed: () => ref.invalidate(scanResultsProvider),
              icon: const Icon(Icons.refresh, color: AppColors.signal),
              label: Text('다시 스캔',
                  style: AppType.mono(size: 13, color: AppColors.signal)),
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
                    _tip('RC카/교구의 전원이 켜져 있는지 확인하세요.'),
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
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: Radii.card,
        child: SurfaceCard(
          padding: const EdgeInsets.symmetric(
              horizontal: Gap.md, vertical: Gap.sm + 2),
          child: Row(
            children: [
              Icon(
                device.isKnownModule
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth,
                color: device.isKnownModule
                    ? AppColors.signal
                    : AppColors.textMuted,
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(device.id,
                        style: AppType.mono(
                            size: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (device.rssi != null)
                Text('${device.rssi} dBm',
                    style:
                        AppType.mono(size: 11, color: AppColors.textMuted)),
              Gap.w8,
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnStateChip extends StatelessWidget {
  const _ConnStateChip({required this.state});
  final BtConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (state) {
      BtConnectionState.connected => (AppColors.signal, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제'),
      BtConnectionState.disconnected => (AppColors.textMuted, '대기'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.baseBg,
        borderRadius: Radii.pill,
        border: Border.all(color: color),
      ),
      child: Text(text, style: AppType.mono(size: 11, color: color)),
    );
  }
}
