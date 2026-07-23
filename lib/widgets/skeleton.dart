// Author: eduino
// 상태 세트 통일(D1) — 로딩=스켈레톤 / 에러=재시도. (빈=EmptyState · 미연결=ConnectCtaBanner)
//   화면마다 같은 패턴으로 로딩/에러를 표현해 일관성을 준다.

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// 얇은 shimmer 블록 — 콘텐츠 자리 표시(로딩).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: const [
                Color(0xFFE9EDF2),
                Color(0xFFF4F7FA),
                Color(0xFFE9EDF2),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// 카드형 스켈레톤 행(아이콘칩 + 2줄) — 리스트 로딩 자리표시.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Skeleton(width: 40, height: 40, radius: 13),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 140, height: 13),
                SizedBox(height: 8),
                Skeleton(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 로딩 리스트 — SkeletonTile 여러 개.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      separatorBuilder: (_, __) => Gap.h8,
      itemBuilder: (_, __) => const SkeletonTile(),
    );
  }
}

/// 에러 상태(재시도) — D1. 아이콘 + 안내 + 재시도 버튼.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.accent = AppColors.signal,
  });
  final String message;
  final VoidCallback onRetry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.warn),
            Gap.h16,
            Text(message,
                textAlign: TextAlign.center,
                style: AppType.mono(
                    size: 13, color: AppColors.textMuted, height: 1.5)),
            Gap.h24,
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
