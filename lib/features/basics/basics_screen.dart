// Author: eduino
// 통신 기초 예제 — "보이는 통신" 교보재. 버튼을 누르면 실제 전송되는 프로토콜 문자열을 보여준다.
// 명령 → 로봇 동작 → 오가는 라인(ASCII)을 눈으로 익힌다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/surface_card.dart';

class _Example {
  const _Example(this.label, this.frame, this.desc, this.send);
  final String label;
  final String frame;
  final String desc;
  final void Function(CarController) send;
}

class BasicsScreen extends ConsumerWidget {
  const BasicsScreen({super.key});

  static final List<_Example> _examples = [
    _Example('전진', 'MOV:F', '앞으로 이동', (c) => c.move(MoveDir.f)),
    _Example('후진', 'MOV:B', '뒤로 이동', (c) => c.move(MoveDir.b)),
    _Example('좌회전', 'MOV:L', '왼쪽으로 회전', (c) => c.move(MoveDir.l)),
    _Example('우회전', 'MOV:R', '오른쪽으로 회전', (c) => c.move(MoveDir.r)),
    _Example('정지', 'STP:', '즉시 정지(안전)', (c) => c.stop()),
    _Example('속도 50%', 'SPD:50', '최대 속도 상한 50%', (c) => c.setSpeedCap(50)),
    _Example('LED 켜기', 'LED:1', 'LED 점등', (c) => c.ledOnOff(true)),
    _Example('LED 끄기', 'LED:0', 'LED 소등', (c) => c.ledOnOff(false)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionProvider).isConnected;
    final log = ref.watch(terminalProvider);
    final car = ref.read(carControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.signal),
                Gap.w16,
                Expanded(
                  child: Text(
                    '버튼을 누르면 아래처럼 실제 명령이 전송됩니다.\n형식: <명령>:<값>  (한 줄 = 한 동작)',
                    style: AppType.mono(
                        size: 12, color: AppColors.textMuted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            mainAxisSpacing: Gap.sm,
            crossAxisSpacing: Gap.sm,
            children: [
              for (final ex in _examples)
                _ExampleButton(
                  example: ex,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ex.send(car);
                  },
                ),
            ],
          ),
        ),
        // 최근 전송/수신 라인 미리보기(교육 포인트)
        Container(
          height: 120,
          width: double.infinity,
          margin: const EdgeInsets.all(Gap.md),
          padding: const EdgeInsets.all(Gap.sm),
          decoration: BoxDecoration(
            color: AppColors.baseBg,
            borderRadius: Radii.chip,
            border: Border.all(color: AppColors.border),
          ),
          child: log.isEmpty
              ? Center(
                  child: Text(
                    connected ? '명령을 눌러보세요.' : '연결 후 눌러야 실제 전송됩니다.',
                    style:
                        AppType.mono(size: 12, color: AppColors.textMuted),
                  ),
                )
              : ListView(
                  reverse: true,
                  children: [
                    for (final e in log.reversed.take(20))
                      Text(
                        '${e.dir == LogDir.out ? "→" : e.dir == LogDir.incoming ? "←" : "·"} ${e.text}',
                        style: AppType.mono(
                          size: 12,
                          color: e.dir == LogDir.incoming
                              ? AppColors.signal
                              : AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ExampleButton extends StatelessWidget {
  const _ExampleButton({required this.example, required this.onTap});
  final _Example example;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.chip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.chip,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(example.label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(example.frame,
                      style: AppType.mono(size: 12, color: AppColors.signal)),
                ],
              ),
            ),
            const Icon(Icons.send, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
