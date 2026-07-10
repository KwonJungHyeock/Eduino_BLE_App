// Author: eduino
// 명령 ↔ 아두이노 코드 매핑 (§5.9, 차별 B). "이 동작 = 이 코드"로 코딩 교육과 연결.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../widgets/surface_card.dart';

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF8CD3B0)),
      tooltip: '코드 복사',
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코드를 복사했어요'), duration: Duration(seconds: 1)),
        );
      },
    );
  }
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const List<(String, String, String)> _maps = [
    (
      '전진 / 조이스틱 위',
      'DRV:80,0  또는  MOV:F',
      'drive(80, 0);\n// 좌우 바퀴를 같은 속도로 정회전',
    ),
    (
      '제자리 회전',
      'DRV:0,100  (우회전)',
      'drive(0, 100);\n// 좌=+, 우=- 로 제자리 회전',
    ),
    (
      '속도 상한',
      'SPD:60',
      'speedCap = map(60, 0,100, 0,255);\nanalogWrite(ENA, pwm); // pwm ≤ speedCap',
    ),
    (
      '정지 (안전)',
      'STP:',
      'motorL.run(RELEASE);\nmotorR.run(RELEASE);',
    ),
    (
      'LED 켜기',
      'LED:1',
      'digitalWrite(LED_PIN, HIGH);',
    ),
    (
      '자율주행 전환',
      'MOD:AUTO',
      'autoMode = true;\n// loop()에서 runAuto() 실행',
    ),
    (
      '파라미터 튜닝',
      'PRM:DIST,25',
      'obstDist = 25;\n// 코드 재업로드 없이 즉시 반영',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          Text(
            '앱이 보내는 명령이 아두이노에서 어떤 코드로 실행되는지 확인하세요. "보이는 통신"이 곧 교보재입니다.',
            style: AppType.mono(size: 13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: Gap.lg),
          for (final m in _maps) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.$1,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Gap.h8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.signalTint,
                      borderRadius: Radii.chip,
                    ),
                    child: Text('명령  ${m.$2}',
                        style: AppType.mono(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.signalDeep)),
                  ),
                  Gap.h8,
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                            Gap.sm, Gap.sm, 40, Gap.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1726),
                          borderRadius: Radii.chip,
                        ),
                        child: Text(m.$3,
                            style: AppType.mono(
                                size: 12,
                                color: const Color(0xFF8CD3B0),
                                height: 1.5)),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _CopyButton(text: m.$3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap.h16,
          ],
        ],
      ),
    );
  }
}
