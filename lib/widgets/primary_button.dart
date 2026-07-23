// Author: eduino
// 공용 Primary 버튼 — 5상태 통일(B1/B3): default / pressed / disabled / loading / focus.
//   pressed: scale .96 + 그림자↓(120ms) · disabled: 그레이 + 그림자 제거 + 커서 불가
//   loading: 인라인 스피너 + 중복 탭 잠금 · focus: 키보드/스위치 접근 focus 링
//   햅틱 medium(전송·주요 액션) · Semantics 버튼 라벨(E). 최소 높이 52·터치 44(B6).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.color = AppColors.signal,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed; // null = disabled
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  final Color color;
  final bool expand;
  final double height;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _down = false;
  bool _focused = false;

  bool get _disabled => widget.onPressed == null || widget.loading;

  void _activate() {
    if (_disabled) return;
    HapticFeedback.mediumImpact(); // Primary = medium(C4)
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final bg = _disabled ? AppColors.chipGray : c;
    final fg = _disabled ? AppColors.chipGrayIcon : Colors.white;
    final shadow = _disabled
        ? const <BoxShadow>[]
        : (_down ? Shadows.pressed : Shadows.glow(c));

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 18, color: fg),
        if (widget.loading || widget.icon != null) const SizedBox(width: 8),
        Text(widget.loading ? (widget.loadingLabel ?? '처리 중…') : widget.label,
            style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
      ],
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: !_disabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _activate();
            return null;
          }),
        },
        mouseCursor: _disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _disabled ? null : (_) => setState(() => _down = true),
          onTapUp: _disabled ? null : (_) => setState(() => _down = false),
          onTapCancel: _disabled ? null : () => setState(() => _down = false),
          onTap: _disabled ? null : _activate,
          child: AnimatedScale(
            scale: _down ? 0.96 : 1,
            duration: Motion.press,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: Motion.press,
              height: widget.height,
              width: widget.expand ? double.infinity : null,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: Radii.button,
                boxShadow: shadow,
              ),
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      borderRadius: Radii.button,
                      border: Border.all(
                          color: c.withValues(alpha: 0.9), width: 3),
                    )
                  : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
