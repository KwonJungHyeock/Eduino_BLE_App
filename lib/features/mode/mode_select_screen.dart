// Author: eduino
// 사용 모드 선택 — 온보딩 1단계. 무엇을 할지 먼저 고르고(실습/교구), 다음에 모듈을 고른다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/app_mode_providers.dart';
import '../../providers/module_providers.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appModeProvider).valueOrNull;
    final canPop = current != null && context.canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('무엇을 할까요?'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop())
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= Breakpoints.tablet;
            final contentW = c.maxWidth < 640 ? c.maxWidth : 640.0;
            final kitCard = RiseIn(
              child: _ModeCard(
                mode: AppMode.kit,
                title: '교구 학습',
                subtitle: 'RC카 · 스마트 팩토리 · 홈 · 팜을\n앱으로 제어하고 체험',
                icon: Icons.smart_toy_outlined,
                selected: current == AppMode.kit,
                onTap: () => _pick(context, ref, AppMode.kit),
              ),
            );
            final labCard = RiseIn(
              delay: const Duration(milliseconds: 90),
              child: _ModeCard(
                mode: AppMode.lab,
                title: '블루투스 실습',
                subtitle: '연결·시리얼 통신·AT 커맨드로\n통신 원리를 직접 학습',
                icon: Icons.bluetooth,
                selected: current == AppMode.lab,
                onTap: () => _pick(context, ref, AppMode.lab),
              ),
            );
            // 카드는 내용에 맞는 자연스러운 크기(화면을 꽉 채우지 않음) → 완성도.
            // 세로 여백이 남으면 가운데 정렬, 부족하면 스크롤.
            return Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: contentW,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.lg, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '이 앱으로 하고 싶은 것을\n아래에서 하나만 골라주세요.',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '나중에 설정에서 언제든 바꿀 수 있어요.',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: Gap.lg),
                        // 넓은 화면: 두 카드를 좌우로(높이 맞춤). 좁은 화면: 위아래로.
                        if (wide)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: kitCard),
                                Gap.w16,
                                Expanded(child: labCard),
                              ],
                            ),
                          )
                        else ...[
                          kitCard,
                          Gap.h16,
                          labCard,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, AppMode m) async {
    HapticFeedback.selectionClick();
    await ref.read(appModeProvider.notifier).select(m);
    if (!context.mounted) return;
    final hasModule = ref.read(moduleProvider).valueOrNull != null;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(hasModule ? Routes.home : Routes.module);
    }
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final AppMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = mode == AppMode.kit ? AppColors.accent : AppColors.signal;
    // 화이트 일변도 완화 — 카드에 은은한 톤 배경, 선택 시 좀 더 진하게.
    final tint = Color.alphaBlend(
      accent.withValues(alpha: selected ? 0.16 : 0.10),
      AppColors.surface,
    );
    return Pressable(
      onTap: onTap,
      haptic: false, // _pick 에서 이미 햅틱 처리.
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.emphasized,
        width: double.infinity,
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: Radii.cardLg,
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? Shadows.glow(accent) : Shadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: Radii.card,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 27),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: Motion.fast,
                  curve: Motion.emphasized,
                  child: Icon(Icons.check_circle, color: accent, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
