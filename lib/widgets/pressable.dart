// Author: eduino
// 공용 마이크로 인터랙션 — 누르면 살짝 눌리는 스케일 + 햅틱(밝고 친근한 톤).
// 카드/타일을 감싸 "만질 수 있는 것" 느낌을 준다. 장식이 아니라 조작 피드백.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final bool haptic;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: Motion.fast,
        curve: Motion.emphasized,
        child: widget.child,
      ),
    );
  }
}

/// 화면 진입 시 아래에서 살짝 떠오르며 페이드인 — 리스트 항목을 순차 등장시킬 때.
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Motion.base);
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (!_disposed && mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.emphasized);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
