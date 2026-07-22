// Author: eduino
// 조이스틱 — 스틱 위치를 7개 단일 문자 명령(g/b/l/r/q/w/s)으로 매핑.
// 중앙 데드존=s. 아날로그 throttle/속도상한 없음(확장 펌웨어 트랙으로 분리). 표시="전송 → g".

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/neo_joystick.dart';
import '../../widgets/pressable.dart';

class JoystickScreen extends ConsumerStatefulWidget {
  const JoystickScreen({super.key});

  @override
  ConsumerState<JoystickScreen> createState() => _JoystickScreenState();
}

class _JoystickScreenState extends ConsumerState<JoystickScreen> {
  DriveCmd _cmd = DriveCmd.stop;

  /// 스틱 벡터(위=+dy, 오른쪽=+dx) → 8방위 → 7개 명령. 중앙=정지.
  DriveCmd _cmdFor(Offset v) {
    if (v.distance < 0.30) return DriveCmd.stop; // 데드존
    final deg = math.atan2(v.dy, v.dx) * 180 / math.pi; // 0=오른쪽, 90=위
    if (deg >= 67.5 && deg < 112.5) return DriveCmd.forward; // 위
    if (deg >= 22.5 && deg < 67.5) return DriveCmd.rotRight; // 우상 = 우회전
    if (deg >= -22.5 && deg < 22.5) return DriveCmd.right; // 오른쪽
    if (deg >= 112.5 && deg < 157.5) return DriveCmd.rotLeft; // 좌상 = 좌회전
    if (deg >= 157.5 || deg < -157.5) return DriveCmd.left; // 왼쪽
    return DriveCmd.back; // 아래쪽 반원 = 후진
  }

  void _onVector(Offset v) {
    final cmd = _cmdFor(v);
    if (cmd != _cmd) setState(() => _cmd = cmd);
    ref.read(carControllerProvider).driveCmd(cmd);
  }

  void _release() {
    setState(() => _cmd = DriveCmd.stop);
    ref.read(carControllerProvider).driveStop();
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          children: [
            RiseIn(child: _CmdReadout(cmd: _cmd)),
            Gap.h16,
            Expanded(
              child: RiseIn(
                delay: const Duration(milliseconds: 70),
                child: _Panel(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('DRIVE STICK',
                            style: AppType.mono(
                                size: 10,
                                color: AppColors.textMuted,
                                letterSpacing: 2)),
                      ),
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(builder: (context, c) {
                            final size = (c.maxWidth < c.maxHeight
                                    ? c.maxWidth
                                    : c.maxHeight)
                                .clamp(160.0, 320.0)
                                .toDouble();
                            return NeoJoystick(
                              size: size,
                              enabled: connected,
                              color: AppColors.accent, // RC 모드 코랄
                              onChanged: _onVector,
                              onReleased: _release,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Gap.h12,
            Text(
              '스틱을 기울인 방향으로 명령이 전송돼요. 놓으면 자동 정지(s).',
              textAlign: TextAlign.center,
              style: AppType.mono(size: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 전송 명령 표시 — "전송 → g" + 한글 라벨 + 방향 글리프. 코랄.
class _CmdReadout extends StatelessWidget {
  const _CmdReadout({required this.cmd});
  final DriveCmd cmd;

  IconData get _icon => switch (cmd) {
        DriveCmd.forward => Icons.keyboard_arrow_up,
        DriveCmd.back => Icons.keyboard_arrow_down,
        DriveCmd.left => Icons.keyboard_arrow_left,
        DriveCmd.right => Icons.keyboard_arrow_right,
        DriveCmd.rotLeft => Icons.rotate_left,
        DriveCmd.rotRight => Icons.rotate_right,
        DriveCmd.stop => Icons.stop,
      };

  @override
  Widget build(BuildContext context) {
    final isStop = cmd == DriveCmd.stop;
    final accent = AppColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.tintOf(accent),
        borderRadius: Radii.cardLg,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isStop ? AppColors.chipGray : accent,
              borderRadius: Radii.card,
            ),
            child: Icon(_icon,
                color: isStop ? AppColors.chipGrayIcon : Colors.white, size: 30),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('전송 명령 · COMMAND',
                    style: AppType.mono(
                        size: 10, color: AppColors.listDesc, letterSpacing: 2)),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('전송 → ',
                        style: AppType.mono(
                            size: 15, color: AppColors.listTitle)),
                    Text(cmd.code,
                        style: AppType.mono(
                            size: 28,
                            weight: FontWeight.w800,
                            color: isStop ? AppColors.listDesc : accent)),
                    Gap.w12,
                    Text(cmd.label,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.listTitle)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: Shadows.soft,
      ),
      child: child,
    );
  }
}
