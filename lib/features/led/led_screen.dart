// Author: eduino
// LED 제어 (§5.5): ON/OFF + 프리셋 컬러(LED:r,g,b) + 밝기 표현. 게임패드 톤과 맞춘 라이트 UI.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/surface_card.dart';

class LedScreen extends ConsumerStatefulWidget {
  const LedScreen({super.key});

  @override
  ConsumerState<LedScreen> createState() => _LedScreenState();
}

class _LedScreenState extends ConsumerState<LedScreen> {
  bool _on = false;
  Color _color = const Color(0xFF1C7DF3);

  static const List<Color> _presets = [
    Color(0xFFE53935), // red
    Color(0xFFF59E0B), // amber
    Color(0xFF43A047), // green
    Color(0xFF1C7DF3), // blue
    Color(0xFF8E24AA), // purple
    Color(0xFF00BCD4), // cyan
    Color(0xFFFFFFFF), // white
  ];

  void _toggle(bool v) {
    HapticFeedback.selectionClick();
    setState(() => _on = v);
    ref.read(carControllerProvider).ledOnOff(v);
  }

  void _pick(Color c) {
    HapticFeedback.selectionClick();
    setState(() {
      _color = c;
      _on = true;
    });
    ref.read(carControllerProvider).ledRgb(
          (c.r * 255).round(),
          (c.g * 255).round(),
          (c.b * 255).round(),
        );
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
            // 현재 상태 프리뷰
            SurfaceCard(
              child: Column(
                children: [
                  Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: _on ? _color : AppColors.surfaceHigh,
                      borderRadius: Radii.card,
                      boxShadow: _on
                          ? [
                              BoxShadow(
                                color: _color.withValues(alpha: 0.5),
                                blurRadius: 28,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        _on ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: _on ? Colors.white : AppColors.textMuted,
                        size: 40,
                      ),
                    ),
                  ),
                  Gap.h16,
                  Row(
                    children: [
                      Text('전원',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Switch(
                        value: _on,
                        onChanged: connected ? _toggle : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap.h24,
            Text('컬러 (RGB)',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            Wrap(
              spacing: Gap.md,
              runSpacing: Gap.md,
              children: [
                for (final c in _presets)
                  _Swatch(
                    color: c,
                    selected: _on && _color.toARGB32() == c.toARGB32(),
                    enabled: connected,
                    onTap: () => _pick(c),
                  ),
              ],
            ),
            const Spacer(),
            if (!connected)
              Text('연결 후 사용할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: AppType.mono(size: 12, color: AppColors.textMuted)),
            Text(
              '단색 LED면 ON/OFF만, 네오픽셀이면 컬러가 반영됩니다.',
              textAlign: TextAlign.center,
              style: AppType.mono(size: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.signal : AppColors.border,
              width: selected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}
