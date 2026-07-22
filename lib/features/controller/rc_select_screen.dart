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
import '../../widgets/kit_illustration.dart';
import '../../widgets/responsive.dart';
import '../kit/kit_profile.dart';

class RcSelectScreen extends ConsumerWidget {
  const RcSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(rcProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('RC 주행하기')),
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
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: _RcCard(
                  profile: KitProfile.forType(type),
                  selected: current?.type == type,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await ref.read(rcProfileProvider.notifier).select(type);
                    if (!context.mounted) return;
                    // 선택 즉시 해당 프로파일의 컨트롤러로 진입.
                    if (context.canPop()) {
                      context.pushReplacement(Routes.controller);
                    } else {
                      context.go(Routes.controller);
                    }
                  },
                ),
              ),
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

class _RcCard extends StatelessWidget {
  const _RcCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final KitProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 교구 모드 = 코랄 accent. 선택 시 강조 보더 + elevation.
    const accent = AppColors.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.card,
      child: Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(
            color: selected ? accent : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? Shadows.lift : Shadows.tap,
        ),
        child: Row(
          children: [
            _ProductThumb(profile: profile),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.listTitle)),
                      ),
                      Gap.w8,
                      _WheelBadge(wheels: profile.wheels),
                    ],
                  ),
                  Gap.h4,
                  Text(profile.tagline,
                      style: AppType.mono(
                          size: 11, color: AppColors.textMuted, height: 1.4)),
                  Gap.h8,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _tag('주행'),
                      if (profile.hasUltrasonic) _tag('초음파 자율'),
                      _tag(
                        profile.hasLineSensor ? 'IR 라인' : '라인 옵션',
                        muted: !profile.hasLineSensor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap.w8,
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected ? accent : AppColors.chevron,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, {bool muted = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: muted ? AppColors.chipGray : AppColors.tintOf(AppColors.accent),
          borderRadius: Radii.chip,
        ),
        child: Text(text,
            style: AppType.mono(
              size: 10.5,
              weight: FontWeight.w700,
              color: muted ? AppColors.chipGrayIcon : AppColors.accent,
            )),
      );
}

class _WheelBadge extends StatelessWidget {
  const _WheelBadge({required this.wheels});
  final int wheels;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintOf(AppColors.accent),
        borderRadius: Radii.pill,
      ),
      child: Text('$wheels휠',
          style: AppType.mono(
              size: 9.5, weight: FontWeight.w800, color: AppColors.accent)),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.profile});
  final KitProfile profile;
  static const double _size = 104;

  @override
  Widget build(BuildContext context) {
    final illustration = KitIllustration(
      art: kitArtFor(profile.type),
      size: _size,
    );
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: Radii.chip,
        child: Image.asset(
          profile.assetImage,
          fit: BoxFit.cover,
          // 실사진 파일이 없으면 코드 일러스트로 폴백(§6.4).
          errorBuilder: (context, error, stack) => illustration,
        ),
      ),
    );
  }
}
