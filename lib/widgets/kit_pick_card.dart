// Author: eduino
// 킷 선택 카드 공통 컴포넌트(B3) — 교구(스마트킷)·RC 두 카테고리가 같은 패턴을 쓴다.
// 제품 사진 + 이름(+휠 배지) + 태그라인 + 능력칩 + 선택 체크. accent 로 모드 색만 바꾼다.

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../features/kit/kit_profile.dart';
import 'kit_illustration.dart';

/// 능력칩 1개 — 라벨 + 흐림(옵션/미지원) 여부.
class KitTag {
  const KitTag(this.label, {this.muted = false});
  final String label;
  final bool muted;
}

class KitPickCard extends StatelessWidget {
  const KitPickCard({
    super.key,
    required this.profile,
    required this.selected,
    required this.accent,
    required this.tags,
    required this.onTap,
    this.wheelBadge = false,
  });

  final KitProfile profile;
  final bool selected;
  final Color accent;
  final List<KitTag> tags;
  final VoidCallback onTap;
  final bool wheelBadge; // 이름 옆 "N휠" 배지(RC 전용).

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
            color: selected ? accent : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? Shadows.lift : Shadows.tap,
        ),
        child: Row(
          children: [
            _Thumb(profile: profile),
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
                      if (wheelBadge) ...[
                        Gap.w8,
                        _Badge(text: '${profile.wheels}휠', accent: accent),
                      ],
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
                      for (final t in tags) _Chip(tag: t, accent: accent),
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
}

class _Chip extends StatelessWidget {
  const _Chip({required this.tag, required this.accent});
  final KitTag tag;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tag.muted ? AppColors.chipGray : AppColors.tintOf(accent),
        borderRadius: Radii.chip,
      ),
      child: Text(tag.label,
          style: AppType.mono(
            size: 10.5,
            weight: FontWeight.w700,
            color: tag.muted ? AppColors.chipGrayIcon : accent,
          )),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.accent});
  final String text;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintOf(accent),
        borderRadius: Radii.pill,
      ),
      child: Text(text,
          style: AppType.mono(
              size: 9.5, weight: FontWeight.w800, color: accent)),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.profile});
  final KitProfile profile;
  static const double _size = 104;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: Radii.chip,
        child: Image.asset(
          profile.assetImage,
          fit: BoxFit.cover,
          // 실사진 파일이 없으면 코드 일러스트로 폴백(§6.4).
          errorBuilder: (context, error, stack) =>
              KitIllustration(art: kitArtFor(profile.type), size: _size),
        ),
      ),
    );
  }
}
