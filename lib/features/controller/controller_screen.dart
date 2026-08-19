// Author: eduino
// 방향 버튼 — 상/하/좌/우 = g/b/l/r, 제자리좌/우회전 = q/w. 대각선·속도상한 제거.
// 누르는 동안 이동, 떼면 정지(s). 단일 문자 명령(기본 RC 펌웨어).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/drive_cmd_display.dart';
import '../../widgets/pressable.dart';
import '../../widgets/orientation_fill.dart';

class ControllerScreen extends ConsumerStatefulWidget {
  const ControllerScreen({super.key});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen> {
  DriveCmd _cmd = DriveCmd.stop;

  void _press(DriveCmd c) {
    setState(() => _cmd = c);
    ref.read(carControllerProvider).driveCmd(c);
  }

  void _stop() {
    setState(() => _cmd = DriveCmd.stop);
    ref.read(carControllerProvider).driveStop();
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: OrientationFillColumn(
          children: [
            RiseIn(child: DriveCmdDisplay(cmd: _cmd)),
            const Spacer(),
            // 십자 방향 패드(대각선 제거).
            _CrossPad(enabled: connected, onPress: _press, onStop: _stop),
            const SizedBox(height: 22),
            // 제자리 좌/우 회전(누르는 동안 회전, 떼면 정지).
            Row(
              children: [
                Expanded(
                  child: _HoldButton(
                    label: '제자리좌회전',
                    sub: 'q',
                    icon: Icons.rotate_left,
                    enabled: connected,
                    onPress: () => _press(DriveCmd.rotLeft),
                    onRelease: _stop,
                  ),
                ),
                Gap.w12,
                Expanded(
                  child: _HoldButton(
                    label: '제자리우회전',
                    sub: 'w',
                    icon: Icons.rotate_right,
                    enabled: connected,
                    onPress: () => _press(DriveCmd.rotRight),
                    onRelease: _stop,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text('버튼을 누르는 동안 이동하고, 손을 떼면 정지(s)합니다.',
                textAlign: TextAlign.center,
                style: AppType.mono(size: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// 십자 방향 패드 — 상(g)·하(b)·좌(l)·우(r) + 중앙 정지(s). 모서리 비움.
class _CrossPad extends StatelessWidget {
  const _CrossPad({
    required this.enabled,
    required this.onPress,
    required this.onStop,
  });
  final bool enabled;
  final void Function(DriveCmd) onPress;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = (c.maxWidth < 360 ? c.maxWidth : 360.0);
      final cell = (side - 2 * Gap.sm) / 3;
      Widget slot(DriveCmd? cmd) => SizedBox(
            width: cell,
            height: cell,
            child: cmd == null
                ? const SizedBox.shrink()
                : _DirButton(
                    cmd: cmd,
                    enabled: enabled,
                    onPress: onPress,
                    onStop: onStop,
                  ),
          );
      return SizedBox(
        width: side,
        height: side,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              slot(null),
              slot(DriveCmd.forward),
              slot(null),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              slot(DriveCmd.left),
              slot(DriveCmd.stop),
              slot(DriveCmd.right),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              slot(null),
              slot(DriveCmd.back),
              slot(null),
            ]),
          ],
        ),
      );
    });
  }
}

class _DirButton extends StatefulWidget {
  const _DirButton({
    required this.cmd,
    required this.enabled,
    required this.onPress,
    required this.onStop,
  });
  final DriveCmd cmd;
  final bool enabled;
  final void Function(DriveCmd) onPress;
  final VoidCallback onStop;

  @override
  State<_DirButton> createState() => _DirButtonState();
}

class _DirButtonState extends State<_DirButton> {
  bool _down = false;
  bool get _isStop => widget.cmd == DriveCmd.stop;

  IconData get _icon => switch (widget.cmd) {
        DriveCmd.forward => Icons.keyboard_arrow_up,
        DriveCmd.back => Icons.keyboard_arrow_down,
        DriveCmd.left => Icons.keyboard_arrow_left,
        DriveCmd.right => Icons.keyboard_arrow_right,
        DriveCmd.stop => Icons.stop,
        _ => Icons.circle,
      };

  void _press() {
    if (!widget.enabled) return;
    setState(() => _down = true);
    HapticFeedback.selectionClick();
    if (_isStop) {
      widget.onStop();
    } else {
      widget.onPress(widget.cmd);
    }
  }

  void _release() {
    if (!widget.enabled) return;
    setState(() => _down = false);
    if (!_isStop) widget.onStop(); // 떼면 정지
  }

  @override
  Widget build(BuildContext context) {
    // 정지=코랄 채움 / 방향=코랄 tint(눌림 시 코랄).
    final Color bg = _down
        ? (_isStop ? AppColors.accent : AppColors.tintOf(AppColors.accent))
        : (_isStop
            ? AppColors.tintOf(AppColors.accent)
            : AppColors.surface);
    final Color fg = _isStop
        ? (_down ? Colors.white : AppColors.accent)
        : (_down ? AppColors.accent : AppColors.listTitle);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.cmd.label,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.4,
        child: Listener(
          onPointerDown: (_) => _press(),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: AnimatedScale(
            scale: _down ? 0.93 : 1.0,
            duration: Motion.fast,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: Radii.card,
                border: Border.all(
                  color: _down ? AppColors.accent : AppColors.cardBorder,
                  width: _down ? 2 : 1,
                ),
                boxShadow: _down ? null : Shadows.tap,
              ),
              alignment: Alignment.center,
              child: Icon(_icon, size: 40, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// 누르는 동안 유지되는 버튼(좌/우회전).
class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.enabled,
    required this.onPress,
    required this.onRelease,
  });
  final String label;
  final String sub;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _press() {
    if (!widget.enabled) return;
    setState(() => _down = true);
    HapticFeedback.selectionClick();
    widget.onPress();
  }

  void _release() {
    if (!widget.enabled) return;
    setState(() => _down = false);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: Listener(
        onPointerDown: (_) => _press(),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: Motion.fast,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: _down ? AppColors.accent : AppColors.surface,
              borderRadius: Radii.card,
              border: Border.all(
                color: _down ? AppColors.accent : AppColors.cardBorder,
                width: _down ? 2 : 1,
              ),
              boxShadow: _down ? null : Shadows.tap,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon,
                    color: _down ? Colors.white : AppColors.accent, size: 22),
                Gap.w8,
                Flexible(
                  child: Text(widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _down ? Colors.white : AppColors.listTitle)),
                ),
                Gap.w8,
                Text(widget.sub,
                    style: AppType.mono(
                        size: 12,
                        weight: FontWeight.w700,
                        color: _down
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.listDesc)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
