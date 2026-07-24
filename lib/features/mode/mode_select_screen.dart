// Author: eduino
// 사용 모드 선택 — 온보딩 1단계. 카드 탭=선택, 하단 고정 버튼=확정·진행(명시적).
// 모드 색 토큰(교구=코랄 / 실습=블루)은 AppMode.color 로 통일해 홈 배너 등 전역과 공유.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../widgets/primary_button.dart';
import '../../providers/app_mode_providers.dart';
import '../../providers/module_providers.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive.dart';

class ModeSelectScreen extends ConsumerStatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  ConsumerState<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends ConsumerState<ModeSelectScreen> {
  AppMode? _selected;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(appModeProvider).valueOrNull;
    // 기본 선택 = 교구 학습(주력 제품군). 이미 고른 모드가 있으면 그것을 초기 선택.
    _selected ??= current ?? AppMode.kit;
    final canPop = current != null && context.canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('무엇을 할까요?'),
        leading: canPop
            ? IconButton(
                tooltip: '뒤로',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop())
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= Breakpoints.tablet;
            final contentW = c.maxWidth < 640 ? c.maxWidth : 640.0;

            final kitCard = _ModeCard(
              accent: AppMode.kit.color,
              icon: Icons.smart_toy_outlined,
              title: AppMode.kit.title, // 교구 학습
              desc: 'RC카·스마트 팩토리·홈·팜을\n앱으로 제어·체험',
              selected: _selected == AppMode.kit,
              onTap: () => _select(AppMode.kit),
            );
            final labCard = _ModeCard(
              accent: AppMode.lab.color,
              icon: Icons.bluetooth,
              title: AppMode.lab.title, // 블루투스 실습
              desc: '연결·시리얼·AT 커맨드로\n통신 원리 학습',
              selected: _selected == AppMode.lab,
              onTap: () => _select(AppMode.lab),
            );

            return Center(
              child: SizedBox(
                width: contentW,
                child: Column(
                  children: [
                    Expanded(
                      // 카드+안내를 세로 중앙 정렬(상단 쏠림·하단 여백 과다 해소),
                      // 내용이 길면 스크롤로 자연스럽게 흐르게(작은 화면 안전).
                      child: LayoutBuilder(
                        builder: (context, inner) => SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              Gap.lg, 18, Gap.lg, 12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight:
                                    (inner.maxHeight - 30).clamp(0, 4000)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            // 헤더는 화면 타이틀로만, 여기선 보조 안내 한 줄만(중복 제거).
                            const Text(
                              '나중에 설정에서 언제든 바꿀 수 있어요.',
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textMuted),
                            ),
                            const SizedBox(height: Gap.lg),
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
                    ),
                    _StartBar(
                      accent: _selected!.color,
                      enabled: _selected != null,
                      onTap: _confirm,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _select(AppMode m) {
    if (_selected == m) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = m);
  }

  Future<void> _confirm() async {
    final m = _selected;
    if (m == null) return;
    HapticFeedback.selectionClick();
    await ref.read(appModeProvider.notifier).select(m);
    if (!context.mounted) return;
    // 설정에서 진입한 경우 pop(모드 변경 반영), 온보딩이면 다음 단계로.
    final hasModule = ref.read(moduleProvider).valueOrNull != null;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(hasModule ? Routes.home : Routes.module);
    }
  }
}

/// 공통 모드 카드 — {accent, icon, title, desc, selected}. 교구/실습이 동일 컴포넌트.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      accent.withValues(alpha: selected ? 0.14 : 0.08),
      AppColors.surface,
    );
    return Pressable(
      onTap: onTap,
      haptic: false, // _select 에서 처리.
      semanticLabel: '$title 모드 선택',
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.emphasized,
        // 두 카드 높이 균형(내용 달라도 최소 높이 통일).
        constraints: const BoxConstraints(minHeight: 152),
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: Radii.cardLg,
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.16),
            width: selected ? 2 : 1,
          ),
          // 선택 시 elevation 강조(입체감).
          boxShadow: selected ? Shadows.lift : Shadows.soft,
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
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(desc,
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

/// 하단 고정 확정 버튼 — 선택한 모드 색으로 "이 모드로 시작".
class _StartBar extends StatelessWidget {
  const _StartBar({
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 8, Gap.lg, 14),
      child: PrimaryButton(
        label: '이 모드로 시작',
        color: accent,
        height: 54,
        onPressed: enabled ? onTap : null,
      ),
    );
  }
}
