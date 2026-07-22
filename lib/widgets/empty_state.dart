// Author: eduino
// 공용 빈 화면 / 안내 상태 — 부드러운 틴트 원 안의 아이콘(또는 커스텀 일러스트) + 안내 + 액션.
// 밝고 친근한 톤. "아무것도 없음"을 벌주는 느낌이 아니라 다음 행동을 안내.

import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'pressable.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.art,
    this.accent = AppColors.signal,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? art; // 커스텀 일러스트를 넣고 싶을 때(icon 대신)
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: RiseIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              art ??
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon ?? Icons.info_outline,
                        size: 42, color: accent),
                  ),
              Gap.h24,
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              if (message != null) ...[
                Gap.h8,
                Text(message!,
                    textAlign: TextAlign.center,
                    style: AppType.mono(
                        size: 12, color: AppColors.textMuted, height: 1.5)),
              ],
              if (actionLabel != null && onAction != null) ...[
                Gap.h24,
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 미연결 시 기능 화면 상단에 얹는 "길을 여는" CTA 배너(B1).
/// 밝은 블루 톤 + 명시적 "연결하기" 버튼. 단순 비활성 대신 다음 행동을 연다.
class ConnectCtaBanner extends StatelessWidget {
  const ConnectCtaBanner({super.key, required this.onConnect});
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.md, 12, Gap.md, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.labTint,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.signal.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.signal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bluetooth_searching,
                color: Colors.white, size: 20),
          ),
          Gap.w12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('먼저 블루투스를 연결하세요',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.listTitle)),
                SizedBox(height: 2),
                Text('연결하면 이 화면의 기능을 바로 써 볼 수 있어요',
                    style: TextStyle(fontSize: 11.5, color: AppColors.listDesc)),
              ],
            ),
          ),
          Gap.w8,
          FilledButton(
            onPressed: onConnect,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const StadiumBorder(),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('연결하기'),
          ),
        ],
      ),
    );
  }
}

/// 상단에 얹는 비차단(non-blocking) 미연결 안내 배너 — 눌러서 연결로 이동.
class DisconnectedBanner extends StatelessWidget {
  const DisconnectedBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warn.withValues(alpha: 0.10),
          borderRadius: Radii.card,
          border: Border.all(color: AppColors.warn.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth_disabled,
                color: AppColors.warn, size: 20),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('블루투스가 연결되지 않았어요',
                      style: AppType.mono(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('탭하면 연결 화면으로 이동해요',
                      style: AppType.mono(size: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.warn),
          ],
        ),
      ),
    );
  }
}
