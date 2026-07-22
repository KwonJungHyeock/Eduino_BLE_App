// Author: eduino
// 상단 상태바 (§5.2): 모듈·기기명·연결색·배터리·거리. 통신은 provider 로만 만난다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../app/theme.dart';
import '../core/bt/bt_transport.dart';
import '../providers/bt_providers.dart';
import '../providers/module_providers.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final tele = ref.watch(telemetryProvider);
    final device = ref.watch(transportProvider).connectedDevice;
    final module = ref.watch(moduleProvider).valueOrNull ?? BtModule.ble;
    final connected = conn == BtConnectionState.connected;

    // 통일 상태 토큰(지시서 0.1): 미연결=회색 / 스캔·대기=노랑 / 연결됨=민트.
    final (color, label) = switch (conn) {
      BtConnectionState.connected => (AppColors.mint, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔 중'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제 중'),
      BtConnectionState.disconnected => (AppColors.chipGrayIcon, '미연결'),
    };
    final bg = connected
        ? AppColors.tintOf(AppColors.mint)
        : color == AppColors.warn
            ? AppColors.warn.withValues(alpha: 0.10)
            : AppColors.chipGray;

    return Material(
      color: bg,
      child: InkWell(
        // 상태바 탭 → 연결 화면(끊겼을 때 바로 재연결). 편의성(B2).
        onTap: () => context.push(Routes.connect),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              _Dot(color: color, pulse: connected),
              Gap.w8,
              Text(label,
                  style: AppType.mono(
                      size: 12, weight: FontWeight.w700, color: color)),
              if (connected) ...[
                Gap.w8,
                Text('· ${device?.displayName ?? module.title}',
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppType.mono(size: 12, color: AppColors.listTitle)),
              ] else ...[
                Gap.w8,
                _Chip(text: module.title),
              ],
              const Spacer(),
              if (connected && tele.distanceCm != null) ...[
                _metric(Icons.straighten, '${tele.distanceCm}cm'),
                Gap.w8,
              ],
              // 배터리는 펌웨어가 실제 잔량을 보낼 때만 노출(항목2 · 근거 없는 "--" 제거).
              if (connected && tele.batteryPercent != null)
                _metric(Icons.battery_full, '${tele.batteryPercent}%')
              else if (!connected) ...[
                Text('탭하여 연결',
                    style: AppType.mono(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.listDesc)),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.chevron),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text, style: AppType.mono(size: 12, color: AppColors.textPrimary)),
        ],
      );
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final glow = widget.pulse ? 0.3 + 0.5 * _c.value : 0.0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: widget.pulse
                ? [BoxShadow(color: widget.color.withValues(alpha: glow), blurRadius: 8)]
                : null,
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.chipGray,
        borderRadius: Radii.chip,
      ),
      child: Text(text,
          style: AppType.mono(size: 11, color: AppColors.listDesc, letterSpacing: 0.5)),
    );
  }
}
