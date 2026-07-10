// Author: eduino
// 키트 선택 (차별 C, §5.1). 실사진 에셋 슬롯 사용, 없으면 라인 아이콘 폴백.
// 선택 결과가 사용 가능한 모드/UI 를 결정한다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/kit_providers.dart';
import 'kit_profile.dart';

class KitSelectScreen extends ConsumerWidget {
  const KitSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(kitProfileProvider).valueOrNull;
    final canPop = current != null; // 이미 선택된 상태면 변경 진입 → 뒤로가기 허용.

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 키트 선택'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Text(
              '보유한 EDUINO 키트를 고르면 딱 맞는 컨트롤 레이아웃과 기능이 열립니다.',
              style: AppType.mono(size: 13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: Gap.lg),
            for (final type in KitProfile.all) ...[
              _KitCard(
                profile: KitProfile.forType(type),
                selected: current?.type == type,
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await ref.read(kitProfileProvider.notifier).select(type);
                  if (!context.mounted) return;
                  context.go(Routes.connect);
                },
              ),
              Gap.h16,
            ],
          ],
        ),
      ),
    );
  }
}

class _KitCard extends StatelessWidget {
  const _KitCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final KitProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.card,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(
            color: selected ? AppColors.signal : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 실사진 슬롯 — 없으면 아이콘 폴백(장식 이미지 금지, §6.4).
            _ProductImage(profile: profile),
            Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Gap.h4,
                        Text(profile.tagline,
                            style: AppType.mono(
                                size: 12, color: AppColors.textMuted)),
                        Gap.h8,
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _tag(profile.motorSummary),
                            if (profile.hasUltrasonic) _tag('초음파'),
                            _tag(profile.hasLineSensor ? 'IR 라인' : 'IR 없음',
                                muted: !profile.hasLineSensor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.chevron_right,
                    color: selected ? AppColors.signal : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, {bool muted = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.baseBg,
          borderRadius: Radii.chip,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: AppType.mono(
              size: 11,
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
            )),
      );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.profile});
  final KitProfile profile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radii.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.baseBg,
          child: Image.asset(
            profile.assetImage,
            fit: BoxFit.cover,
            // 실사진 파일이 아직 없으면 아이콘 플레이스홀더(생성형 데코 아님).
            errorBuilder: (context, error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(profile.fallbackIcon,
                      size: 48, color: AppColors.textMuted),
                  Gap.h8,
                  Text('실사진 에셋 슬롯',
                      style: AppType.mono(
                          size: 10, color: AppColors.textMuted, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
