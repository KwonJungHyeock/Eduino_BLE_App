// Author: eduino
// 블루투스 컨트롤러 메뉴 — 주행 제어 모드 리스트업.
// 구현: 조이스틱 · 방향 버튼 · 자율주행·실험. 후속(P6+): 기울기 · LED · 음성 = "준비 중".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../home/home_screen.dart' show HomeMenuTile;

class ControllerMenuScreen extends ConsumerWidget {
  const ControllerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionProvider).isConnected;

    return Scaffold(
      appBar: AppBar(title: const Text('블루투스 컨트롤러')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            if (!connected)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: Text(
                  '연결되지 않았습니다. 조작은 되지만 실제 전송은 연결 후 동작합니다.',
                  style: AppType.mono(
                      size: 12, color: AppColors.warn, height: 1.5),
                ),
              ),
            Text('주행 제어',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.gamepad_outlined,
              title: '조이스틱',
              subtitle: '아날로그 벡터 주행 · 속도 게이지 (메인)',
              onTap: () => context.push(Routes.joystick),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.control_camera_outlined,
              title: '방향 버튼',
              subtitle: '8방향 D-패드 + 정지',
              onTap: () => context.push(Routes.dpad),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.auto_mode_outlined,
              title: '자율주행 · 실험',
              subtitle: '수동/자율 전환 · 센서 텔레메트리 · 실시간 튜닝',
              accent: AppColors.accent,
              onTap: () => context.push(Routes.auto),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.lightbulb_outline,
              title: 'LED 제어',
              subtitle: 'ON/OFF · 프리셋 컬러(RGB)',
              onTap: () => context.push(Routes.led),
            ),
            Gap.h24,
            Text('추가 제어 (준비 중)',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.screen_rotation_outlined,
              title: '기울기(틸트) 제어',
              subtitle: '가속도계로 조향 — 다음 업데이트',
              enabled: false,
              trailingBadge: '준비 중',
              onTap: () {},
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.mic_none_outlined,
              title: '음성 제어',
              subtitle: '온디바이스 STT 명령 — 다음 업데이트',
              enabled: false,
              trailingBadge: '준비 중',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
