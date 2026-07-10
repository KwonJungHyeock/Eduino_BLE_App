// Author: eduino
// 상단 상태바 (§5.2): 모듈·기기명·연결색·배터리·거리. 통신은 provider 로만 만난다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/bt/bt_transport.dart';
import '../providers/bt_providers.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final tele = ref.watch(telemetryProvider);
    final device = ref.watch(transportProvider).connectedDevice;

    final (color, label) = switch (conn) {
      BtConnectionState.connected => (AppColors.signal, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔 중'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제 중'),
      BtConnectionState.disconnected => (AppColors.textMuted, '미연결'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _Dot(color: color, pulse: conn == BtConnectionState.connected),
          Gap.w8,
          Text(label, style: AppType.mono(size: 12, color: color)),
          Gap.w8,
          Container(width: 1, height: 14, color: AppColors.border),
          Gap.w8,
          const _Chip(text: 'HM-10 BLE'),
          Gap.w8,
          Flexible(
            child: Text(
              device?.displayName ?? '기기 없음',
              overflow: TextOverflow.ellipsis,
              style: AppType.mono(size: 12, color: AppColors.textPrimary),
            ),
          ),
          const Spacer(),
          if (tele.distanceCm != null) ...[
            _metric(Icons.straighten, '${tele.distanceCm}cm'),
            Gap.w8,
          ],
          _metric(
            Icons.battery_full,
            tele.batteryPercent != null ? '${tele.batteryPercent}%' : '--',
          ),
        ],
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
        color: AppColors.baseBg,
        borderRadius: Radii.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          style: AppType.mono(size: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
    );
  }
}
