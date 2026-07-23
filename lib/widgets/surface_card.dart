// Author: eduino
// 공용 표면 카드 — 다크 elevation 단계 표현 (§6.4). 장식 없이 여백/보더로 깊이만.

import 'package:flutter/material.dart';

import '../app/theme.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.md),
    this.color = AppColors.surface,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: Shadows.soft, // 소프트 뎁스(A1)
      ),
      child: child,
    );
  }
}
