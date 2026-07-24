// Author: eduino
// 커스텀 아날로그 조이스틱 (§6.4 · §5.2). 스프링 복귀, 정밀 그리드/글로우.
// 출력: 정규화 벡터 (dx, dy) 각 -1..1 (위=+throttle, 오른쪽=+steer).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

class NeoJoystick extends StatefulWidget {
  const NeoJoystick({
    super.key,
    required this.size,
    required this.onChanged,
    this.onReleased,
    this.enabled = true,
    this.color = AppColors.signal,
  });

  final double size;

  /// 노브·벡터선·글로우 색(모드 accent). 기본 블루, RC=코랄.
  final Color color;

  /// 드래그 중 정규화 벡터. y 는 위가 +(전진) 되도록 부호 반전되어 전달됨.
  final void Function(Offset vector) onChanged;
  final VoidCallback? onReleased;
  final bool enabled;

  @override
  State<NeoJoystick> createState() => _NeoJoystickState();
}

class _NeoJoystickState extends State<NeoJoystick>
    with SingleTickerProviderStateMixin {
  Offset _knob = Offset.zero; // 픽셀 오프셋(중심 기준)
  late final AnimationController _spring;
  Animation<Offset>? _springAnim;
  bool _dragging = false;

  double get _radius => widget.size / 2;
  double get _knobRadius => widget.size * 0.16;
  double get _maxTravel => _radius - _knobRadius - 6;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_springAnim != null) {
          setState(() => _knob = _springAnim!.value);
        }
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _emit() {
    final v = _maxTravel == 0 ? Offset.zero : _knob / _maxTravel;
    // 화면 y 아래가 +이므로 전진(+throttle)을 위해 부호 반전.
    widget.onChanged(Offset(v.dx, -v.dy));
  }

  void _updateKnob(Offset local) {
    final center = Offset(_radius, _radius);
    var delta = local - center;
    final dist = delta.distance;
    if (dist > _maxTravel) {
      delta = delta / dist * _maxTravel;
    }
    setState(() => _knob = delta);
    _emit();
  }

  void _onStart(Offset local) {
    if (!widget.enabled) return;
    _spring.stop();
    _dragging = true;
    HapticFeedback.selectionClick();
    _updateKnob(local);
  }

  void _onEnd() {
    if (!widget.enabled) return;
    _dragging = false;
    _springAnim = Tween<Offset>(begin: _knob, end: Offset.zero).animate(
      CurvedAnimation(parent: _spring, curve: Curves.elasticOut),
    );
    _spring.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onChanged(Offset.zero);
    widget.onReleased?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: GestureDetector(
        onPanStart: (d) => _onStart(d.localPosition),
        onPanUpdate: (d) {
          if (_dragging) _updateKnob(d.localPosition);
        },
        onPanEnd: (_) => _onEnd(),
        onPanCancel: _onEnd,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _JoystickPainter(
            knob: _knob,
            radius: _radius,
            knobRadius: _knobRadius,
            active: _dragging,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({
    required this.knob,
    required this.radius,
    required this.knobRadius,
    required this.active,
    required this.color,
  });

  final Offset knob;
  final double radius;
  final double knobRadius;
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(radius, radius);

    // 베이스 표면(노브와 대비되도록 살짝 가라앉힌 뮤트 톤)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.baseBg,
    );
    // 외곽 링
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.border,
    );

    // 방사형 눈금(계기판 느낌, 12분할)
    final tickPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final outer = center + Offset(math.cos(a), math.sin(a)) * (radius - 6);
      final inner = center + Offset(math.cos(a), math.sin(a)) * (radius - 16);
      canvas.drawLine(inner, outer, tickPaint);
    }

    // 중심 십자선
    final cross = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
        center - const Offset(10, 0), center + const Offset(10, 0), cross);
    canvas.drawLine(
        center - const Offset(0, 10), center + const Offset(0, 10), cross);

    final knobCenter = center + knob;

    // 조향 벡터 라인
    if (knob.distance > 2) {
      canvas.drawLine(
        center,
        knobCenter,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // 노브 글로우(절제, active 시에만)
    if (active) {
      canvas.drawCircle(
        knobCenter,
        knobRadius + 8,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // 노브 그림자(솟아오른 퍽처럼 보이도록 — 유휴 시에도 대비 확보)
    canvas.drawCircle(
      knobCenter + const Offset(0, 2),
      knobRadius,
      Paint()
        ..color = AppColors.signal.withValues(alpha: active ? 0.0 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // 노브 본체(유휴 시 솔리드 블루로 베이스와 확실히 구분)
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()..color = active ? color : AppColors.signal,
    );
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
    // 노브 중앙 도트
    canvas.drawCircle(
      knobCenter,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.knob != knob || old.active != active || old.color != color;
}
