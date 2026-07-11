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
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            children: [
              Text(
                '이 앱으로 하고 싶은 것을 골라주세요. 나중에 설정에서 바꿀 수 있어요.',
                style: AppType.mono(
                    size: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: Gap.lg),
              Expanded(
                child: _ModeCard(
                  mode: AppMode.kit,
                  title: '교구 학습',
                  subtitle: 'RC카 · 스마트 팩토리 · 홈 · 팜을\n앱으로 제어하고 체험',
                  icon: Icons.smart_toy_outlined,
                  selected: current == AppMode.kit,
                  onTap: () => _pick(context, ref, AppMode.kit),
                ),
              ),
              Gap.h16,
              Expanded(
                child: _ModeCard(
                  mode: AppMode.lab,
                  title: '블루투스 실습',
                  subtitle: '연결·시리얼 통신·AT 커맨드로\n통신 원리를 직접 학습',
                  icon: Icons.bluetooth,
                  selected: current == AppMode.lab,
                  onTap: () => _pick(context, ref, AppMode.lab),
                ),
              ),
            ],
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.card,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x141B3A6B), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: Radii.card,
              ),
              child: Icon(icon, color: accent, size: 32),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Gap.h8,
                  Text(subtitle,
                      style: AppType.mono(
                          size: 12, color: AppColors.textMuted, height: 1.5)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? accent : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
