// Author: eduino
// 블루투스 컨트롤러 메뉴 — 주행 제어 모드 리스트업.
// 구현: 조이스틱 · 방향 버튼 · 자율주행·실험. 후속(P6+): 기울기 · LED · 음성 = "준비 중".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../widgets/circuit.dart';
import '../../widgets/responsive.dart';
import '../home/home_screen.dart' show HomeMenuTile;

class ControllerMenuScreen extends ConsumerWidget {
  const ControllerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionProvider).isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RC 주행 컨트롤러'),
        actions: [
          IconButton(
            tooltip: 'RC카 설정 (휠·핀)',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.rcConfig),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
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
            const NodeRailHeader('주행 제어', color: AppColors.signal),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.gamepad_outlined,
              title: '조이스틱',
              subtitle: '아날로그 벡터 주행 · 속도 게이지 (메인)',
              accent: AppColors.signal,
              onTap: () => context.push(Routes.joystick),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.control_camera_outlined,
              title: '방향 버튼',
              subtitle: '8방향 D-패드 + 정지',
              accent: AppColors.signalDeep,
              onTap: () => context.push(Routes.dpad),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.screen_rotation_outlined,
              title: '기울기(틸트) 제어',
              subtitle: '기기를 기울여 조향·주행',
              accent: AppColors.mint,
              onTap: () => context.push(Routes.tilt),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.mic_none_outlined,
              title: '음성 제어',
              subtitle: '말로 명령 (전진·정지·좌/우 …)',
              accent: AppColors.accent,
              onTap: () => context.push(Routes.voice),
            ),
          ],
        ),
      ),
    );
  }
}
