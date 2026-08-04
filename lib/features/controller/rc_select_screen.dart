// Author: eduino
// RC 주행 키트 선택 — 2휠/메탈/4휠을 실제 제품 사진 카드로 노출(실물 인식 우선).
// 선택 → RC 프로파일 저장 → 컨트롤러 진입. 프로파일이 노출 기능(라인 등)을 결정한다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/kit_providers.dart';
import '../../widgets/kit_pick_card.dart';
import '../../widgets/responsive.dart';
import '../../widgets/home_button.dart';
import '../kit/kit_profile.dart';

class RcSelectScreen extends ConsumerWidget {
  const RcSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(rcProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RC 주행하기'),
        actions: const [HomeButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
          children: [
            Text(
              '내 RC카를 고르면 딱 맞는 주행 컨트롤러가 열립니다.\n'
              '없는 기능(라인트레이싱 등)은 자동으로 숨겨져요.',
              style:
                  AppType.mono(size: 13, color: AppColors.textMuted, height: 1.6),
            ),
            const SizedBox(height: Gap.lg),
            _catLabel('RC 주행 · 3종'),
            for (final type in KitProfile.rcKits)
              Builder(builder: (context) {
                final p = KitProfile.forType(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: Gap.md),
                  child: KitPickCard(
                    profile: p,
                    selected: current?.type == type,
                    accent: AppColors.accent, // 교구 모드 코랄.
                    wheelBadge: true,
                    // 3종 모두 동일한 4방식 주행(단일 문자). 자율/라인은 확장 트랙.
                    tags: const [
                      KitTag('조이스틱'),
                      KitTag('방향·기울기'),
                      KitTag('음성'),
                    ],
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await ref.read(rcProfileProvider.notifier).select(type);
                      if (!context.mounted) return;
                      // 계층 유지(A1): 홈 → 3종 선택 → 컨트롤러. 뒤로가면 3종 선택으로.
                      context.push(Routes.controller);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _catLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: Text(t,
            style: AppType.mono(
                size: 12, color: AppColors.textMuted, letterSpacing: 2)),
      );
}
