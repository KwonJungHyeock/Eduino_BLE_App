// Author: eduino
// RC 주행 컨트롤러 — 선택한 RC 키트 프로파일이 노출 기능을 결정한다(차별 C).
//   주행 컨트롤러 ✓ · 자율주행(초음파) ✓ · 라인트레이싱 = 프로파일/토글로 게이팅.
// 화면 컴포넌트는 하나씩만 — 프로파일이 "무엇을 보여줄지"만 정한다(코드 중복 아님).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/kit_providers.dart';
import '../../widgets/circuit.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive.dart';
import '../kit/kit_profile.dart';
import '../home/home_screen.dart' show HomeMenuTile;

class ControllerMenuScreen extends ConsumerWidget {
  const ControllerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionProvider).isConnected;
    // RC 프로파일(미선택이면 2휠 기본). 프로파일이 기능 노출을 결정.
    final rc = ref.watch(rcProfileProvider).valueOrNull ??
        KitProfile.forType(KitType.twoWheel);
    final lineOn = ref.watch(lineSensorEnabledProvider).valueOrNull ?? false;
    final showLine = rc.capLineTraceBuiltIn || lineOn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RC 주행 컨트롤러'),
        actions: [
          IconButton(
            tooltip: 'RC 키트 변경',
            icon: const Icon(Icons.cached),
            // 계층 유지(A1): 뒤로가면 3종 선택으로. 스택에 없으면 새로 연다.
            onPressed: () => context.canPop()
                ? context.pop()
                : context.push(Routes.rcSelect),
          ),
          IconButton(
            tooltip: 'RC카 설정 (휠·핀)',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.rcConfig),
          ),
          const SizedBox(width: 4), // A5: 우측 아이콘 잘림 방지 여백.
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
          children: [
            // 현재 RC 카드(실물 인식) — 프로파일 확인.
            _RcHeaderCard(rc: rc),
            Gap.h16,
            // 연결 우선 CTA(미연결) — 교구 모드 코랄 accent(A2).
            if (!connected) ...[
              ConnectCtaBanner(
                accent: AppColors.accent,
                onConnect: () => context.push(Routes.connect),
              ),
              Gap.h16,
            ],

            // 색상 통일(A2): 기능 아이콘칩 전부 코랄 tint / 섹션 라벨 뉴트럴 그레이.
            const NodeRailHeader('주행 제어'),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.gamepad_outlined,
              title: '조이스틱',
              subtitle: '아날로그 벡터 주행 · 속도 게이지 (메인)',
              accent: AppColors.accent,
              onTap: () => context.push(Routes.joystick),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.control_camera_outlined,
              title: '방향 버튼',
              subtitle: '8방향 D-패드 + 정지',
              accent: AppColors.accent,
              onTap: () => context.push(Routes.dpad),
            ),
            Gap.h8,
            HomeMenuTile(
              icon: Icons.screen_rotation_outlined,
              title: '기울기(틸트) 제어',
              subtitle: '기기를 기울여 조향·주행',
              accent: AppColors.accent,
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

            // 자율주행 — 초음파 있는 프로파일만(3종 공통).
            if (rc.capAutoUltra) ...[
              const SizedBox(height: 22),
              const NodeRailHeader('자율주행'),
              Gap.h8,
              HomeMenuTile(
                icon: Icons.sensors,
                title: '자율주행 (초음파)',
                subtitle: '초음파로 장애물 회피',
                accent: AppColors.accent,
                onTap: () => context.push(Routes.auto),
              ),
            ],

            // 라인트레이싱 — 4휠 내장 또는 라인센서 토글 ON 일 때만.
            const SizedBox(height: 22),
            const NodeRailHeader('라인트레이싱'),
            Gap.h8,
            if (showLine)
              HomeMenuTile(
                icon: Icons.route_outlined,
                title: '라인트레이싱',
                subtitle: rc.capLineTraceBuiltIn
                    ? '라인센서로 선 따라 주행 (내장)'
                    : '라인센서(옵션)로 선 따라 주행',
                accent: AppColors.accent,
                onTap: () => context.push(Routes.line),
              ),
            // 2휠·메탈: 라인센서 별매 → 사용 토글 노출.
            if (!rc.capLineTraceBuiltIn)
              _LineSensorToggle(
                value: lineOn,
                onChanged: (v) =>
                    ref.read(lineSensorEnabledProvider.notifier).set(v),
              ),
          ],
        ),
      ),
    );
  }
}

/// 현재 RC 프로파일 요약 카드 — 실물 사진 + 이름 + 지원 기능 칩.
class _RcHeaderCard extends StatelessWidget {
  const _RcHeaderCard({required this.rc});
  final KitProfile rc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: Shadows.tap,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(rc.assetImage,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                        color: AppColors.tintOf(AppColors.accent),
                        child: const Icon(Icons.directions_car,
                            color: AppColors.accent),
                      )),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rc.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.listTitle)),
                const SizedBox(height: 3),
                Text('${rc.wheels}휠 · ${rc.motorSummary}',
                    style: AppType.mono(size: 11, color: AppColors.listDesc)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 라인센서(별매) 사용 토글 — 켜면 라인트레이싱 노출.
class _LineSensorToggle extends StatelessWidget {
  const _LineSensorToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.chipGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sensors_outlined,
                color: AppColors.chipGrayIcon, size: 22),
          ),
          Gap.w12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('라인센서 사용',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.listTitle)),
                SizedBox(height: 2),
                Text('별매 IR 라인센서를 달았다면 켜세요',
                    style: TextStyle(fontSize: 12, color: AppColors.listDesc)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
