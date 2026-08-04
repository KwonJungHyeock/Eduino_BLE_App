// Author: eduino
// 기울기(틸트) — 기울기 방향을 7개 단일 문자 명령(g/b/l/r/q/w/s)으로 매핑. 중립=s.
// 수평=정지 캘리브레이션 유지. 민감도 슬라이더·칩. THR/STR 수치 제거, "전송 → g" 표시.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/drive_cmd_display.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/surface_card.dart';

class TiltScreen extends ConsumerStatefulWidget {
  const TiltScreen({super.key});

  @override
  ConsumerState<TiltScreen> createState() => _TiltScreenState();
}

class _TiltScreenState extends ConsumerState<TiltScreen> {
  StreamSubscription<AccelerometerEvent>? _sub;
  bool _active = false;
  // 슬라이더 범위 0.4~1.6 → 보통(1.0)이 정중앙. 기본값=보통(교실 안전).
  static const double _kMaxSens = 1.6;
  double _sensitivity = 1.0;
  double _baseX = 0, _baseY = 3.5;
  Offset _vec = Offset.zero; // 시각화용 (dx=steer, dy=throttle 위=+)
  DriveCmd _cmd = DriveCmd.stop;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// 기울기 벡터 → 8방위 → 7개 명령. 중립(데드존)=s.
  DriveCmd _cmdFor(Offset v) {
    if (v.distance < 0.30) return DriveCmd.stop;
    final deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    if (deg >= 67.5 && deg < 112.5) return DriveCmd.forward;
    if (deg >= 22.5 && deg < 67.5) return DriveCmd.rotRight;
    if (deg >= -22.5 && deg < 22.5) return DriveCmd.right;
    if (deg >= 112.5 && deg < 157.5) return DriveCmd.rotLeft;
    if (deg >= 157.5 || deg < -157.5) return DriveCmd.left;
    return DriveCmd.back;
  }

  void _toggle(bool v) {
    HapticFeedback.selectionClick();
    setState(() => _active = v);
    if (v) {
      _sub = accelerometerEventStream().listen(_onEvent);
    } else {
      _sub?.cancel();
      _sub = null;
      ref.read(carControllerProvider).driveStop();
      setState(() {
        _vec = Offset.zero;
        _cmd = DriveCmd.stop;
      });
    }
  }

  void _onEvent(AccelerometerEvent e) {
    const dead = 0.15;
    double norm(double v) {
      final n = (v / 6.0).clamp(-1.0, 1.0) * _sensitivity;
      return n.abs() < dead ? 0.0 : n.clamp(-1.0, 1.0);
    }

    // 좌우 축 보정: 기기를 왼쪽으로 기울이면 가속도계 x가 +로 커지므로,
    // 부호를 뒤집어야 왼쪽 기울임=좌회전(l), 오른쪽 기울임=우회전(r)이 된다.
    final steer = norm(-(e.x - _baseX));
    final throttle = norm(-(e.y - _baseY));
    final vec = Offset(steer, throttle);
    final cmd = _cmdFor(vec);
    if (vec != _vec || cmd != _cmd) {
      setState(() {
        _vec = vec;
        _cmd = cmd;
      });
    }
    ref.read(carControllerProvider).driveCmd(cmd);
  }

  Future<void> _calibrate() async {
    HapticFeedback.selectionClick();
    final e = await accelerometerEventStream().first;
    setState(() {
      _baseX = e.x;
      _baseY = e.y;
    });
  }

  Widget _preset(String label, double value) {
    final active = (_sensitivity - value).abs() < 0.05;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _sensitivity = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.tintOf(AppColors.accent)
                : AppColors.baseBg,
            borderRadius: Radii.chip,
            border: Border.all(
                color: active ? AppColors.accent : AppColors.border),
          ),
          child: Text(label,
              style: AppType.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? AppColors.accent : AppColors.textMuted)),
        ),
      ),
    );
  }

  String get _sensGuide {
    if (_sensitivity < 0.8) return '부드럽게 · 많이 기울여도 천천히 (초보용)';
    if (_sensitivity < 1.4) return '보통 · 균형잡힌 반응';
    return '민감 · 조금만 기울여도 크게 움직여요';
  }

  IconData get _sensIcon {
    if (_sensitivity < 0.8) return Icons.spa_outlined;
    if (_sensitivity < 1.4) return Icons.balance;
    return Icons.bolt;
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SurfaceCard(
              child: Column(
                children: [
                  _Level(vec: _vec),
                  Gap.h12,
                  DriveCmdDisplay(cmd: _cmd),
                ],
              ),
            ),
            Gap.h16,
            // 시작/정지: 크고 눈에 잘 띄는 Primary 토글(연결 안 되면 비활성).
            PrimaryButton(
              label: _active ? '기울기 조작 정지' : '기울기 조작 시작',
              icon: _active ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: _active ? AppColors.accent : AppColors.signal,
              onPressed: connected ? () => _toggle(!_active) : null,
            ),
            Gap.h16,
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('민감도',
                          style: AppType.mono(
                              size: 12, color: AppColors.textMuted)),
                      const Spacer(),
                      // %는 최대(높음=1.6) 기준 → 보통(가운데)≈63%, 높음=100%.
                      Text('${(_sensitivity / _kMaxSens * 100).round()}%',
                          style: AppType.mono(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.accent)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _sensitivity,
                      min: 0.4,
                      max: _kMaxSens, // 보통(1.0)이 슬라이더 정중앙에 오도록
                      onChanged: (v) => setState(() => _sensitivity = v),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(_sensIcon, size: 15, color: AppColors.accent),
                      Gap.w8,
                      Expanded(
                        child: Text(_sensGuide,
                            style: AppType.mono(
                                size: 12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  Gap.h12,
                  Row(
                    children: [
                      _preset('낮음', 0.6),
                      Gap.w8,
                      _preset('보통', 1.0),
                      Gap.w8,
                      _preset('높음', 1.6),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _calibrate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('현재 자세를 수평(정지)으로 맞추기'),
            ),
            Gap.h8,
            Text(
              '앞뒤로 기울이면 전진/후진, 좌우로 기울이면 좌/우, 대각선은 회전(q/w)입니다.',
              textAlign: TextAlign.center,
              style: AppType.mono(size: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 수평계 — 기울기 벡터를 코랄 차 아이콘으로 표시.
class _Level extends StatelessWidget {
  const _Level({required this.vec});
  final Offset vec; // dx=steer, dy=throttle(위=+)
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final dx = vec.dx.clamp(-1.0, 1.0) * (w / 2 - 18);
        final dy = -vec.dy.clamp(-1.0, 1.0) * (h / 2 - 18);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: Radii.card,
                border: Border.all(color: AppColors.border),
              ),
            ),
            Container(width: 1, height: h, color: AppColors.border),
            Container(width: w, height: 1, color: AppColors.border),
            Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: vec.dx.clamp(-1.0, 1.0) * 0.5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.45),
                          blurRadius: 16),
                    ],
                  ),
                  child: const Icon(Icons.directions_car,
                      color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
