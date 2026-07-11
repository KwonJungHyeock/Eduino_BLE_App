// Author: eduino
// Signal Board 디자인 언어 — 회로/신호 은유. 장식이 아니라 구조(섹션)와 상태(연결)를 표현.
//  · NodeRailHeader : 섹션을 회로 레일처럼(솔더 노드 + 점선 레일)
//  · SignalTrace    : 연결 상태를 APP↔모듈 신호선으로(연결 시 신호가 흐름)
//  · BreadboardBackground : 아주 옅은 브레드보드 도트 격자
//  · CircuitAccent  : 앱바용 은은한 회로 트레이스

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// 섹션 헤더 — 노드 + 라벨 + 점선 레일.
class NodeRailHeader extends StatelessWidget {
  const NodeRailHeader(this.label, {super.key, this.color = AppColors.textMuted});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.sm, bottom: 2),
      child: Row(
        children: [
          // 솔더 노드(링 + 코어).
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          Gap.w8,
          Text(label,
              style: AppType.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2)),
          Gap.w8,
          Expanded(
            child: CustomPaint(
              painter: _DashRailPainter(AppColors.border),
              size: const Size(double.infinity, 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashRailPainter extends CustomPainter {
  _DashRailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 6.0, gap = 5.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashRailPainter old) => old.color != color;
}

/// 연결 상태 신호선 — 연결 시 신호점이 APP→모듈로 흐른다. 미연결 시 끊긴 회색선.
class SignalTrace extends StatefulWidget {
  const SignalTrace({
    super.key,
    required this.connected,
    this.leftLabel = 'APP',
    this.rightLabel = '모듈',
  });
  final bool connected;
  final String leftLabel;
  final String rightLabel;

  @override
  State<SignalTrace> createState() => _SignalTraceState();
}

class _SignalTraceState extends State<SignalTrace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.connected) _c.repeat();
  }

  @override
  void didUpdateWidget(SignalTrace old) {
    super.didUpdateWidget(old);
    if (widget.connected && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.connected && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.connected ? AppColors.signal : AppColors.textMuted;
    return Row(
      children: [
        Text(widget.leftLabel,
            style: AppType.mono(
                size: 9, color: AppColors.textMuted, letterSpacing: 1)),
        Gap.w8,
        _pin(color),
        Gap.w8,
        Expanded(
          child: SizedBox(
            height: 16,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _WirePainter(
                    connected: widget.connected, progress: _c.value),
              ),
            ),
          ),
        ),
        Gap.w8,
        _pin(color),
        Gap.w8,
        Text(widget.rightLabel,
            style: AppType.mono(
                size: 9, color: AppColors.textMuted, letterSpacing: 1)),
      ],
    );
  }

  Widget _pin(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _WirePainter extends CustomPainter {
  _WirePainter({required this.connected, required this.progress});
  final bool connected;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final base = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = connected
          ? AppColors.signal.withValues(alpha: 0.5)
          : AppColors.border;
    const dash = 6.0, gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), base);
      x += dash + gap;
    }

    if (connected) {
      // 흐르는 신호점(글로우 + 코어).
      final px = size.width * (0.04 + 0.92 * progress);
      canvas.drawCircle(
        Offset(px, y),
        5,
        Paint()
          ..color = AppColors.signal.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(Offset(px, y), 3, Paint()..color = AppColors.signal);
    } else {
      // 끊김 마커(경고 링 + ✕).
      final c = Offset(size.width / 2, y);
      canvas.drawCircle(c, 8, Paint()..color = AppColors.surface);
      canvas.drawCircle(
        c,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.warn,
      );
      final xp = Paint()
        ..color = AppColors.warn
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c + const Offset(-3, -3), c + const Offset(3, 3), xp);
      canvas.drawLine(c + const Offset(3, -3), c + const Offset(-3, 3), xp);
    }
  }

  @override
  bool shouldRepaint(_WirePainter old) =>
      old.progress != progress || old.connected != connected;
}

/// 아주 옅은 브레드보드 도트 격자 — 배경에 회로 기판 은유(절제).
class BreadboardBackground extends StatelessWidget {
  const BreadboardBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BreadboardPainter(),
      child: child,
    );
  }
}

class _BreadboardPainter extends CustomPainter {
  static const double _step = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.signal.withValues(alpha: 0.05);
    for (var y = _step; y < size.height; y += _step) {
      for (var x = _step; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_BreadboardPainter old) => false;
}

/// 앱바용 은은한 회로 트레이스 악센트.
class CircuitAccent extends StatelessWidget {
  const CircuitAccent({super.key, this.color = AppColors.signal, this.width = 64});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 22,
      child: CustomPaint(painter: _CircuitAccentPainter(color)),
    );
  }
}

class _CircuitAccentPainter extends CustomPainter {
  _CircuitAccentPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.45);
    final w = size.width, h = size.height;
    final mid = h / 2;
    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.22, mid)
      ..lineTo(w * 0.22, h * 0.2)
      ..lineTo(w * 0.44, h * 0.2)
      ..moveTo(w * 0.22, mid)
      ..lineTo(w * 0.62, mid)
      ..lineTo(w * 0.62, h * 0.85)
      ..lineTo(w * 0.8, h * 0.85)
      ..moveTo(w * 0.62, mid)
      ..lineTo(w, mid);
    canvas.drawPath(path, line);

    final node = Paint()..color = color.withValues(alpha: 0.7);
    for (final o in [
      Offset(w * 0.22, mid),
      Offset(w * 0.44, h * 0.2),
      Offset(w * 0.62, mid),
      Offset(w * 0.8, h * 0.85),
    ]) {
      canvas.drawCircle(o, 2, node);
    }
  }

  @override
  bool shouldRepaint(_CircuitAccentPainter old) => old.color != color;
}
