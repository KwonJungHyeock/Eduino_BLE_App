// Author: eduino
// 방향 버튼 모드 (§5.3): D-패드(8방향) + 중앙 정지(빨강). press/release 로 MOV 전송. 속도 상한 공유.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/speed_cap_slider.dart';
import '../../widgets/surface_card.dart';

class ControllerScreen extends ConsumerWidget {
  const ControllerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionProvider).isConnected;
    final car = ref.read(carControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _DPad(
                  enabled: connected,
                  onPress: car.move,
                  onStop: car.stop,
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            SurfaceCard(child: const SpeedCapSlider()),
          ],
        ),
      ),
    );
  }
}

/// 3×3 배치: 모서리=대각, 변=직진/좌우, 중앙=정지.
class _DPad extends StatelessWidget {
  const _DPad({
    required this.enabled,
    required this.onPress,
    required this.onStop,
  });

  final bool enabled;
  final void Function(MoveDir) onPress;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    const grid = [
      [MoveDir.fl, MoveDir.f, MoveDir.fr],
      [MoveDir.l, MoveDir.s, MoveDir.r],
      [MoveDir.bl, MoveDir.b, MoveDir.br],
    ];

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: LayoutBuilder(
        builder: (context, c) {
          final side =
              (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight).clamp(0, 360).toDouble();
          final cell = (side - 2 * Gap.sm) / 3;
          return SizedBox(
            width: side,
            height: side,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final row in grid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final dir in row)
                        _DirButton(
                          dir: dir,
                          size: cell,
                          enabled: enabled,
                          onPress: onPress,
                          onStop: onStop,
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DirButton extends StatefulWidget {
  const _DirButton({
    required this.dir,
    required this.size,
    required this.enabled,
    required this.onPress,
    required this.onStop,
  });

  final MoveDir dir;
  final double size;
  final bool enabled;
  final void Function(MoveDir) onPress;
  final VoidCallback onStop;

  @override
  State<_DirButton> createState() => _DirButtonState();
}

class _DirButtonState extends State<_DirButton> {
  bool _down = false;

  bool get _isStop => widget.dir == MoveDir.s;

  IconData get _icon {
    switch (widget.dir) {
      case MoveDir.f:
        return Icons.keyboard_arrow_up;
      case MoveDir.b:
        return Icons.keyboard_arrow_down;
      case MoveDir.l:
        return Icons.keyboard_arrow_left;
      case MoveDir.r:
        return Icons.keyboard_arrow_right;
      case MoveDir.fl:
        return Icons.north_west;
      case MoveDir.fr:
        return Icons.north_east;
      case MoveDir.bl:
        return Icons.south_west;
      case MoveDir.br:
        return Icons.south_east;
      case MoveDir.s:
        return Icons.stop;
    }
  }

  void _press() {
    if (!widget.enabled) return;
    setState(() => _down = true);
    HapticFeedback.selectionClick();
    if (_isStop) {
      widget.onStop();
    } else {
      widget.onPress(widget.dir);
    }
  }

  void _release() {
    if (!widget.enabled) return;
    setState(() => _down = false);
    // 정지 버튼이 아니면 손 떼는 순간 안전 정지.
    if (!_isStop) widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isStop ? AppColors.accent : AppColors.signal;
    final bg = _down
        ? accent.withValues(alpha: _isStop ? 0.9 : 0.22)
        : (_isStop ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface);
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: Radii.chip,
          border: Border.all(
            color: _down ? accent : AppColors.border,
            width: _down ? 2 : 1,
          ),
        ),
        child: Icon(
          _icon,
          size: widget.size * 0.42,
          color: _isStop
              ? (_down ? Colors.white : AppColors.accent)
              : (_down ? accent : AppColors.textPrimary),
        ),
      ),
    );
  }
}
