// Author: eduino
// 기울기(틸트) 제어 (§5.4): 가속도계 → x=조향, y=throttle. 수평=정지 캘리브레이션, 데드존.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/surface_card.dart';

class TiltScreen extends ConsumerStatefulWidget {
  const TiltScreen({super.key});

  @override
  ConsumerState<TiltScreen> createState() => _TiltScreenState();
}

class _TiltScreenState extends ConsumerState<TiltScreen> {
  StreamSubscription<AccelerometerEvent>? _sub;
  bool _active = false;
  double _sensitivity = 1.0;
  double _baseX = 0, _baseY = 3.5; // 캘리브레이션 기준(세로로 든 기본 자세)
  int _throttle = 0, _steer = 0;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _toggle(bool v) {
    HapticFeedback.selectionClick();
    setState(() => _active = v);
    if (v) {
      _sub = accelerometerEventStream().listen(_onEvent);
    } else {
      _sub?.cancel();
      _sub = null;
      ref.read(carControllerProvider).stop();
      setState(() {
        _throttle = 0;
        _steer = 0;
      });
    }
  }

  void _onEvent(AccelerometerEvent e) {
    const dead = 0.15; // 데드존(수평 근처 무시)
    double norm(double v) {
      final n = (v / 6.0).clamp(-1.0, 1.0) * _sensitivity;
      return n.abs() < dead ? 0.0 : n.clamp(-1.0, 1.0);
    }

    final steer = (norm(e.x - _baseX) * 100).round().clamp(-100, 100).toInt();
    final throttle =
        (norm(-(e.y - _baseY)) * 100).round().clamp(-100, 100).toInt();
    if (steer != _steer || throttle != _throttle) {
      setState(() {
        _steer = steer;
        _throttle = throttle;
      });
    }
    ref.read(carControllerProvider).drive(throttle, steer);
  }

  Future<void> _calibrate() async {
    HapticFeedback.selectionClick();
    // 현재 자세를 "수평(정지)" 기준으로 잡는다.
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
                ? AppColors.signal.withValues(alpha: 0.14)
                : AppColors.baseBg,
            borderRadius: Radii.chip,
            border: Border.all(
                color: active ? AppColors.signal : AppColors.border),
          ),
          child: Text(label,
              style: AppType.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? AppColors.signal : AppColors.textMuted)),
        ),
      ),
    );
  }

  String get _sensGuide {
    if (_sensitivity < 0.8) return '부드럽게 · 살짝 기울여도 천천히 (초보용)';
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
                  _Level(throttle: _throttle, steer: _steer),
                  Gap.h16,
                  Text('THR ${_throttle}   STR ${_steer}',
                      style: AppType.mono(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.signalDeep)),
                ],
              ),
            ),
            Gap.h16,
            SurfaceCard(
              child: Row(
                children: [
                  Text('기울기 제어',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Switch(value: _active, onChanged: connected ? _toggle : null),
                ],
              ),
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
                      Text('${(_sensitivity * 100).round()}%',
                          style: AppType.mono(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.signal)),
                    ],
                  ),
                  Slider(
                    value: _sensitivity,
                    min: 0.4,
                    max: 2.0,
                    onChanged: (v) => setState(() => _sensitivity = v),
                  ),
                  Row(
                    children: [
                      Icon(_sensIcon, size: 15, color: AppColors.signal),
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
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('현재 자세를 수평(정지)으로 맞추기'),
            ),
            Gap.h8,
            Text(
              '기기를 앞뒤로 기울이면 전진/후진, 좌우로 기울이면 조향입니다.',
              textAlign: TextAlign.center,
              style: AppType.mono(size: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 수평계 UI — 조향/스로틀 위치를 점으로 표시.
class _Level extends StatelessWidget {
  const _Level({required this.throttle, required this.steer});
  final int throttle;
  final int steer;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final dx = (steer / 100) * (w / 2 - 18);
        final dy = -(throttle / 100) * (h / 2 - 18);
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
            // 폰 기울기 = 차 움직임 연동: 차 아이콘이 기울고(조향) 위아래로(스로틀) 이동.
            Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: (steer / 100) * 0.5, // 좌우 기울임 = 조향 각
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.signal,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.signal.withValues(alpha: 0.45),
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
