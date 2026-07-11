// Author: eduino
// 에듀이노 교구 — 키트 선택 (차별 C). 제품 대표 이미지(맞춤 사이즈, 꽉 채우지 않음) + 제품명.
// 실사진 에셋 슬롯 사용, 없으면 라인 아이콘 폴백. 선택 결과가 사용 가능한 모드/UI 를 결정.

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

    return Scaffold(
      appBar: AppBar(title: const Text('에듀이노 교구')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Text(
              '보유한 EDUINO 교구를 고르면 딱 맞는 컨트롤 레이아웃과 기능이 열립니다.',
              style:
                  AppType.mono(size: 13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: Gap.lg),
            _catLabel('RC카 제어'),
            for (final type in KitProfile.rcKits)
              _kitCard(context, ref, type, current),
            const SizedBox(height: Gap.sm),
            _catLabel('스마트 교구 제어'),
            for (final type in KitProfile.applianceKits)
              _kitCard(context, ref, type, current),
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

  Widget _kitCard(
    BuildContext context,
    WidgetRef ref,
    KitType type,
    KitProfile? current,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: _KitCard(
        profile: KitProfile.forType(type),
        selected: current?.type == type,
        onTap: () async {
          HapticFeedback.selectionClick();
          await ref.read(kitProfileProvider.notifier).select(type);
          if (!context.mounted) return;
          // 선택 즉시 제어판으로(단계 최소화).
          if (context.canPop()) {
            context.pushReplacement(Routes.control);
          } else {
            context.go(Routes.control);
          }
        },
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
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(
            color: selected ? AppColors.signal : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 대표 이미지 — 맞춤 사이즈(정사각 썸네일, contain 으로 여백 유지).
            _ProductThumb(profile: profile),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  Gap.h4,
                  Text(profile.tagline,
                      style: AppType.mono(
                          size: 11, color: AppColors.textMuted, height: 1.4)),
                  Gap.h8,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: profile.isRc
                        ? [
                            if (profile.hasUltrasonic) _tag('초음파'),
                            _tag(profile.hasLineSensor ? 'IR 라인' : 'IR 없음',
                                muted: !profile.hasLineSensor),
                          ]
                        : [
                            for (final c in profile.controls.take(3))
                              _tag(c.label),
                          ],
                  ),
                ],
              ),
            ),
            Gap.w8,
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected ? AppColors.signal : AppColors.textMuted,
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.profile});
  final KitProfile profile;

  static const double _size = 104; // 맞춤 썸네일 크기(화면을 꽉 채우지 않음).

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.baseBg,
        borderRadius: Radii.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          profile.assetImage,
          fit: BoxFit.contain, // 제품이 잘리지 않고 여백을 유지하도록 contain.
          // 실사진 파일이 아직 없으면 아이콘 플레이스홀더(생성형 데코 아님, §6.4).
          errorBuilder: (context, error, stack) => Center(
            child: Icon(profile.fallbackIcon,
                size: 40, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
