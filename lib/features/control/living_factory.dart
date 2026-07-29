// Author: eduino
// Living Twin — "가동 라인 씬"(스마트 팩토리). 명령 상태를 컨베이어 라인으로 표현.
//   가동('1') → 벨트/롤러 회전·물체 흐름·분류 서보 스윙 / 중지('0') → 전부 정지(freeze).
//   ★정직성(A3): 벨트 위 물체·분류는 "작동 미리보기"(연출). 앱은 분류 결과를 수신하지
//   않으므로 "빨강 N개" 같은 가짜 카운트 금지 — 표시 가능한 사실은 가동/정지 + 가동 시간뿐.
//   미연결 → desaturate + "연결하면 라인이 돌아갑니다" 오버레이(팜·홈과 동일 패턴).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FactoryState {
  const FactoryState({
    this.running = false,
    this.live = false,
    this.sortCounts = const {'r': 0, 'g': 0, 'b': 0},
    this.lastSort,
  });
  final bool running; // 컨베이어 가동 여부(보드 y/n 회신 반영).
  final bool live; // 연결 여부.
  final Map<String, int> sortCounts; // 색별 분류 누적(실데이터 · QA 0-3).
  final String? lastSort; // 마지막 분류 색('r'/'g'/'b').

  int get total =>
      (sortCounts['r'] ?? 0) + (sortCounts['g'] ?? 0) + (sortCounts['b'] ?? 0);
}

class LivingFactory extends StatefulWidget {
  const LivingFactory({super.key, required this.state});
  final FactoryState state;

  @override
  State<LivingFactory> createState() => _LivingFactoryState();
}

class _LivingFactoryState extends State<LivingFactory>
    with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  // 감지→판정 단계 연출 — 새 분류(lastSort 변경) 수신 시 1회 재생.
  late final AnimationController _sort = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  Timer? _tick;
  int _secs = 0; // 가동 시간(앱 카운트) — 연결/명령 무관, 실제 표시 가능한 사실.

  static const _sortNames = {'r': '빨강', 'g': '초록', 'b': '파랑'};
  static const _sortColors = {
    'r': Color(0xFFE53935),
    'g': Color(0xFF43A047),
    'b': Color(0xFF1E88E5),
  };

  static const List<double> _mono = <double>[
    0.5276, 0.4291, 0.0433, 0, 14, //
    0.1276, 0.8291, 0.0433, 0, 14, //
    0.1276, 0.4291, 0.4433, 0, 14, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.state.running && widget.state.live) {
        setState(() => _secs++);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LivingFactory old) {
    super.didUpdateWidget(old);
    // 가동 시작(off→on) 시 가동 시간 리셋.
    if (widget.state.running && !old.state.running) _secs = 0;
    // 새 분류 수신(lastSort 변경) → 감지→판정 단계 연출 1회 재생.
    final ls = widget.state.lastSort;
    if (ls != old.state.lastSort &&
        _sortNames.containsKey(ls) &&
        widget.state.live &&
        widget.state.running) {
      _sort.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _loop.dispose();
    _sort.dispose();
    super.dispose();
  }

  // 단계 칩 페이드(등장/퇴장).
  double _stageOpacity(double p) {
    if (p <= 0 || p >= 1) return 0.0;
    if (p < 0.15) return p / 0.15;
    if (p > 0.85) return (1 - p) / 0.15;
    return 1.0;
  }

  Widget _stageChip(String k) {
    final detecting = _sort.value < 0.4;
    final col = _sortColors[k]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: Radii.pill,
        boxShadow: Shadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(detecting ? Icons.radar : Icons.check_circle,
              size: 14, color: detecting ? AppColors.signal : col),
          const SizedBox(width: 5),
          Text(detecting ? '감지' : '판정: ${_sortNames[k]}',
              style: AppType.mono(
                  size: 11,
                  weight: FontWeight.w800,
                  color: AppColors.listTitle)),
        ],
      ),
    );
  }

  String get _uptime {
    final m = (_secs ~/ 60).toString().padLeft(2, '0');
    final s = (_secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.state;
    final live = st.live;
    final running = live && st.running;
    return ClipRRect(
      borderRadius: Radii.cardLg,
      child: AspectRatio(
        aspectRatio: 1.9,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _sort]),
          builder: (context, _) {
            final scene = CustomPaint(
              painter: _LinePainter(
                  running: running,
                  t: _loop.value,
                  lastSort: st.lastSort,
                  sortProgress: _sort.value,
                  sortCounts: st.sortCounts),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: live
                      ? scene
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix(_mono),
                          child: scene,
                        ),
                ),
                // 상태 배지: 가동 중(초록) / 정지(회색) — 명령 상태 반영(A2).
                if (live)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: (running ? AppColors.mint : AppColors.chipGrayIcon)
                                .withValues(alpha: 0.95),
                            borderRadius: Radii.pill,
                          ),
                          child: Row(
                            children: [
                              Icon(running ? Icons.play_arrow : Icons.stop,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(running ? '가동 중' : '정지',
                                  style: AppType.mono(
                                      size: 10,
                                      weight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 가동 시간(앱 카운트) — 유일하게 정직하게 표시 가능한 값.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: Radii.pill,
                          ),
                          child: Text('가동 $_uptime',
                              style: AppType.mono(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                // 감지→판정 단계 칩 — 실 수신 분류(lastSort) 순간을 또렷하게.
                if (live &&
                    _sort.value > 0 &&
                    _sortNames.containsKey(st.lastSort))
                  Positioned(
                    top: 40,
                    left: 10,
                    child: Opacity(
                      opacity: _stageOpacity(_sort.value),
                      child: _stageChip(st.lastSort!),
                    ),
                  ),
                // 정직성 라벨(A3) — 물체/분류는 연출.
                if (live)
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Text('작동 미리보기',
                        style: AppType.mono(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ),
                // 미연결 대기 오버레이(A4).
                if (!live)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Align(
                        alignment: const Alignment(0, -0.62),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: Radii.pill,
                            boxShadow: Shadows.soft,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.precision_manufacturing,
                                  color: AppColors.signal, size: 16),
                              const SizedBox(width: 6),
                              Text('연결하면 라인이 돌아갑니다',
                                  style: AppType.mono(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: AppColors.listTitle)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(
      {required this.running,
      required this.t,
      this.lastSort,
      this.sortProgress = 0,
      this.sortCounts = const {'r': 0, 'g': 0, 'b': 0}});
  final bool running;
  final double t; // 0..1 애니메이션 위상
  final String? lastSort; // 마지막 분류 색('r'/'g'/'b') — 실데이터(QA 0-3).
  final double sortProgress; // 0..1 감지→판정 단계 진행(0=대기).
  final Map<String, int> sortCounts; // 색별 분류 누적(실데이터) — 바구니 적층 표시용.

  static const _blue = AppColors.signal;
  static const _binColors = <String, Color>{
    'r': Color(0xFFE53935),
    'g': Color(0xFF43A047),
    'b': Color(0xFF1E88E5),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final phase = running ? t : 0.0; // 정지 시 모션 freeze.

    // 배경 — 공장 벽/바닥(중립).
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEDF1F5));
    final floorY = h * 0.82;
    canvas.drawRect(Rect.fromLTRB(0, floorY, w, h),
        Paint()..color = const Color(0xFFD5DBE2));

    // 컨베이어 벨트.
    final beltL = w * 0.08, beltR = w * 0.60;
    final beltY = h * 0.50, beltH = h * 0.11;
    final beltMidY = beltY + beltH / 2;
    final beltRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(beltL, beltY, beltR, beltY + beltH),
        Radius.circular(beltH / 2));
    canvas.drawRRect(beltRect, Paint()..color = const Color(0xFF3A4250));
    // 벨트 트레드(이동).
    final tread = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    final gap = 22.0;
    final off = (phase * gap);
    for (double x = beltL + off; x < beltR; x += gap) {
      canvas.drawLine(Offset(x, beltY + 4), Offset(x, beltY + beltH - 4), tread);
    }

    // 롤러(양끝, 회전 스포크).
    final rollerR = beltH * 0.62;
    _roller(canvas, Offset(beltL, beltMidY), rollerR, phase);
    _roller(canvas, Offset(beltR, beltMidY), rollerR, phase);

    // 물체(박스) — 벨트 위를 좌→우로 흐름(연출).
    const nBox = 3;
    for (var i = 0; i < nBox; i++) {
      final p = ((phase + i / nBox) % 1.0);
      final bx = beltL + 14 + (beltR - beltL - 28) * p;
      final by = beltY - 12;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - 9, by, 18, 14), const Radius.circular(3));
      canvas.drawRRect(r, Paint()..color = const Color(0xFFC79A5B));
      canvas.drawRRect(
          r,
          Paint()
            ..color = const Color(0xFF9E7A44)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
    }

    // 스캐너 게이트(벨트 끝) — 감지 단계에 색 하이라이트/펄스.
    final scanX = beltR - 26;
    final scanGlow = (running && sortProgress > 0 && sortProgress < 0.5)
        ? (1 - sortProgress / 0.5)
        : 0.0;
    _scanner(canvas, scanX, beltY, h, scanGlow, lastSort);

    // 분류 서보(벨트 끝 위) — 스윙 암.
    final pivot = Offset(beltR + w * 0.03, beltY - h * 0.02);
    final swing = math.sin(phase * 2 * math.pi) * 0.5; // -0.5..0.5 rad
    final armLen = h * 0.16;
    final armEnd = Offset(pivot.dx + math.sin(swing) * armLen,
        pivot.dy + math.cos(swing) * armLen);
    canvas.drawCircle(pivot, 5, Paint()..color = _blue);
    canvas.drawLine(
        pivot,
        armEnd,
        Paint()
          ..color = _blue
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(armEnd, 4, Paint()..color = const Color(0xFF0E5FC0));

    // 색 분류 수거함 — 빨강/초록/파랑(실제 r/g/b 분류 대상).
    final binY = floorY - h * 0.16, binH = h * 0.16, binW = w * 0.075;
    const keys = ['r', 'g', 'b'];
    final centers = [w * 0.72, w * 0.82, w * 0.92];
    for (var i = 0; i < 3; i++) {
      final cx = centers[i];
      final col = _binColors[keys[i]]!;
      final bin = Path()
        ..moveTo(cx - binW / 2, binY)
        ..lineTo(cx + binW / 2, binY)
        ..lineTo(cx + binW / 2 - 3, binY + binH)
        ..lineTo(cx - binW / 2 + 3, binY + binH)
        ..close();
      canvas.drawPath(bin, Paint()..color = col.withValues(alpha: 0.30));

      // 누적 분류 개수만큼 바닥부터 위로 색 블록 적층(실데이터 · 표시 전용).
      final count = (sortCounts[keys[i]] ?? 0);
      if (count > 0) {
        final blockH = binH * 0.13;
        final gapY = binH * 0.045;
        final rowH = blockH + gapY;
        final pad = binH * 0.07;
        final maxRows = ((binH - pad) ~/ rowH).clamp(1, 40);
        final rows = count > maxRows ? maxRows : count;
        for (var r = 0; r < rows; r++) {
          final yb = binY + binH - pad - r * rowH; // 이 블록의 바닥.
          var yt = yb - blockH; // 이 블록의 상단.
          // 바구니 벽 기울기에 맞춰 폭 테이퍼(위=넓게, 아래=좁게).
          final frac = ((yt - binY) / binH).clamp(0.0, 1.0);
          final inset = 3 * frac + 2.5;
          final bw = binW - 2 * inset;
          // 새 분류 낙하와 연계 — 맨 위 한 칸이 "톡" 떨어져 안착.
          if (r == rows - 1 &&
              running &&
              lastSort == keys[i] &&
              sortProgress > 0.82) {
            final s = (sortProgress - 0.82) / 0.18; // 0..1
            final e = (1 - s) * (1 - s);
            yt -= e * blockH * 2.2;
          }
          final block = RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - bw / 2, yt, bw, blockH),
              Radius.circular(blockH * 0.3));
          canvas.drawRRect(block, Paint()..color = col.withValues(alpha: 0.90));
          canvas.drawRRect(
              block,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.22)
                ..strokeWidth = 0.8
                ..style = PaintingStyle.stroke);
        }
      }

      canvas.drawPath(
          bin,
          Paint()
            ..color = col
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }

    // 분류되는 물체 — 감지→판정 단계 연출(실 수신 lastSort · sortProgress).
    //   0..0.4 감지: 스캐너 아래 정지(무채) · 0.4..1 판정: 색 부여 후 해당 함으로 낙하.
    if (running &&
        lastSort != null &&
        _binColors.containsKey(lastSort) &&
        sortProgress > 0) {
      final idx = keys.indexOf(lastSort!);
      final tx = centers[idx];
      final col = _binColors[lastSort]!;
      final startY = beltY - 12;
      final p = sortProgress;
      final Offset pos;
      final Color boxCol;
      if (p < 0.4) {
        pos = Offset(scanX, startY); // 감지 단계 — 스캐너 아래 정지.
        boxCol = const Color(0xFFC79A5B); // 아직 무채(크래프트).
      } else {
        final tp = (p - 0.4) / 0.6; // 0..1 판정+낙하.
        pos = Offset(scanX + (tx - scanX) * tp, startY + (binY - startY) * tp);
        boxCol = col; // 판정 색 부여.
      }
      final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - 7, pos.dy - 6, 14, 12),
          const Radius.circular(2));
      canvas.drawRRect(box, Paint()..color = boxCol);
      canvas.drawRRect(
          box,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
    }

    // 지지 다리.
    final leg = Paint()
      ..color = const Color(0xFF8894A3)
      ..strokeWidth = 4;
    canvas.drawLine(Offset(beltL + 10, beltY + beltH), Offset(beltL + 10, floorY), leg);
    canvas.drawLine(Offset(beltR - 10, beltY + beltH), Offset(beltR - 10, floorY), leg);
  }

  // 스캐너 게이트 — 벨트 위 감지 헤드. glow(0..1)로 렌즈/스캔라인 색 하이라이트.
  void _scanner(Canvas canvas, double x, double beltY, double h, double glow,
      String? sort) {
    final topY = beltY - h * 0.14;
    final botY = beltY + 2;
    final post = Paint()
      ..color = const Color(0xFF556070)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 15, topY), Offset(x - 15, botY), post);
    canvas.drawLine(Offset(x + 15, topY), Offset(x + 15, botY), post);
    // 상단 센서 헤드.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(x - 19, topY - 6, x + 19, topY + 6),
            const Radius.circular(3)),
        Paint()..color = const Color(0xFF3A4250));
    // 렌즈 — 감지 중이면 판정 색으로 점등.
    final lensCol = (glow > 0 && sort != null && _binColors.containsKey(sort))
        ? _binColors[sort]!
        : const Color(0xFF7C8797);
    canvas.drawCircle(Offset(x, topY),
        3.2, Paint()..color = Color.lerp(const Color(0xFF7C8797), lensCol, glow)!);
    // 스캔 라인 + 펄스 링(감지 중).
    if (glow > 0) {
      canvas.drawLine(
          Offset(x - 13, botY - 4),
          Offset(x + 13, botY - 4),
          Paint()
            ..color = lensCol.withValues(alpha: 0.5 * glow)
            ..strokeWidth = 2);
      canvas.drawCircle(
          Offset(x, (topY + botY) / 2),
          10 + 10 * (1 - glow),
          Paint()
            ..color = lensCol.withValues(alpha: 0.35 * glow)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  void _roller(Canvas canvas, Offset c, double r, double phase) {
    canvas.drawCircle(c, r, Paint()..color = _blue);
    canvas.drawCircle(c, r,
        Paint()..color = const Color(0xFF0E5FC0)..strokeWidth = 2..style = PaintingStyle.stroke);
    final a = phase * 2 * math.pi;
    final spoke = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2;
    for (var k = 0; k < 2; k++) {
      final ang = a + k * math.pi / 2;
      canvas.drawLine(
          Offset(c.dx - math.cos(ang) * r * 0.7, c.dy - math.sin(ang) * r * 0.7),
          Offset(c.dx + math.cos(ang) * r * 0.7, c.dy + math.sin(ang) * r * 0.7),
          spoke);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.t != t ||
      old.running != running ||
      old.lastSort != lastSort ||
      old.sortProgress != sortProgress ||
      (old.sortCounts['r'] ?? 0) != (sortCounts['r'] ?? 0) ||
      (old.sortCounts['g'] ?? 0) != (sortCounts['g'] ?? 0) ||
      (old.sortCounts['b'] ?? 0) != (sortCounts['b'] ?? 0);
}
