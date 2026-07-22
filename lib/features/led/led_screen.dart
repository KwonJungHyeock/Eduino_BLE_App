// Author: eduino
// LED 제어 (§5.5): 보드 13번 핀 ON/OFF (digitalWrite). 단순·명확한 큰 토글.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../providers/rc_config_providers.dart';

class LedScreen extends ConsumerStatefulWidget {
  const LedScreen({super.key});

  @override
  ConsumerState<LedScreen> createState() => _LedScreenState();
}

class _LedScreenState extends ConsumerState<LedScreen> {
  bool _on = false;
  String? _lastSent; // 마지막 전송 프레임(보이는 통신).

  void _set(bool v) {
    HapticFeedback.mediumImpact();
    final pin = ref.read(rcConfigProvider).valueOrNull?.ledPin ?? 13;
    setState(() {
      _on = v;
      _lastSent = 'LED:$pin,${v ? 1 : 0}';
    });
    ref.read(carControllerProvider).led(pin, v);
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;
    final pin = ref.watch(rcConfigProvider).valueOrNull?.ledPin ?? 13;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // 큰 전구 프리뷰
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _on ? AppColors.sun : AppColors.surface,
                  border: Border.all(
                    color: _on ? AppColors.sun : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: _on
                      ? [
                          BoxShadow(
                            color: AppColors.sun.withValues(alpha: 0.5),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _on ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 84,
                  color: _on ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
            Gap.h24,
            Center(
              child: Text(
                _on ? 'ON' : 'OFF',
                style: AppType.instrument(
                    size: 40, color: _on ? AppColors.sun : AppColors.textMuted),
              ),
            ),
            Gap.h8,
            Center(
              child: Text('보드 D$pin 핀 (digitalWrite)',
                  style: AppType.mono(size: 12, color: AppColors.textMuted)),
            ),
            Gap.h16,
            // 출력 핀 선택(커스텀). 기본 13.
            _PinSelector(
              pin: pin,
              onChanged: (p) =>
                  ref.read(rcConfigProvider.notifier).setLedPin(p),
            ),
            // 실제 전송 payload(보이는 통신) — 연결 시에만 표시(A2).
            if (connected) ...[
              Gap.h12,
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.chipGray,
                    borderRadius: Radii.pill,
                  ),
                  child: Text(
                    _lastSent == null ? '전송 → LED:$pin,0/1' : '전송 → $_lastSent',
                    style: AppType.mono(size: 12, color: AppColors.listDesc),
                  ),
                ),
              ),
            ],
            const Spacer(),
            // 큰 토글 버튼
            _BigToggle(
              on: _on,
              enabled: connected,
              onTap: () => _set(!_on),
            ),
            Gap.h16,
            if (!connected)
              Center(
                child: Text('연결 후 사용할 수 있어요.',
                    style: AppType.mono(size: 12, color: AppColors.textMuted)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 출력 핀 선택 — 디지털 D2~D13 중에서. 실습에서 핀을 바꿔가며 확인.
class _PinSelector extends StatelessWidget {
  const _PinSelector({required this.pin, required this.onChanged});
  final int pin;
  final ValueChanged<int> onChanged;

  static const List<int> _pins = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_input_component,
              size: 20, color: AppColors.chipGrayIcon),
          Gap.w12,
          const Expanded(
            child: Text('출력 핀',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.listTitle)),
          ),
          DropdownButton<int>(
            value: pin,
            underline: const SizedBox.shrink(),
            borderRadius: Radii.card,
            items: [
              for (final p in _pins)
                DropdownMenuItem(
                  value: p,
                  child: Text('D$p', style: AppType.mono(size: 14)),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                HapticFeedback.selectionClick();
                onChanged(v);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BigToggle extends StatelessWidget {
  const _BigToggle({
    required this.on,
    required this.enabled,
    required this.onTap,
  });
  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 미연결=회색 비활성 / 연결·OFF="켜기"(블루) / 연결·ON="끄기"(코랄).
    final Color bg =
        !enabled ? AppColors.chipGray : (on ? AppColors.accent : AppColors.signal);
    final Color fg = !enabled ? AppColors.chipGrayIcon : Colors.white;
    return Semantics(
      button: true,
      enabled: enabled,
      label: on ? 'LED 끄기' : 'LED 켜기',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: Radii.pill,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Radii.pill,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: (on ? AppColors.accent : AppColors.signal)
                          .withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new, color: fg, size: 24),
              Gap.w8,
              Text(on ? '끄기' : '켜기',
                  style: TextStyle(
                      color: fg, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
