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
import '../../widgets/kit_pick_card.dart';
import '../../widgets/responsive.dart';
import 'kit_curriculum.dart';
import 'kit_profile.dart';
import '../../widgets/home_button.dart';

class KitSelectScreen extends ConsumerWidget {
  const KitSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(kitProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('에듀이노 교구'),
        actions: const [HomeButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: pagePadding(context),
          children: [
            Text(
              '보유한 스마트 교구를 고르면 딱 맞는 제어판과 학습이 열립니다.\n(RC카는 홈의 "RC 주행하기"에서 골라 주행해요.)',
              style:
                  AppType.mono(size: 13, color: AppColors.textMuted, height: 1.6),
            ),
            const SizedBox(height: Gap.lg),
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
    final p = KitProfile.forType(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: KitPickCard(
        profile: p,
        selected: current?.type == type,
        accent: AppColors.accent, // 교구 모드 코랄(E3).
        tags: [
          for (final c in p.controls.take(3)) KitTag(c.label),
        ],
        onTap: () async {
          HapticFeedback.selectionClick();
          await ref.read(kitProfileProvider.notifier).select(type);
          if (!context.mounted) return;
          // 강의 커리큘럼이 있으면 학습으로, 없으면(홈 등) 제어판(집 씬) 직행(A1).
          // 학습 콘텐츠는 추후 강의자료 OCR 로 채워지면 자동 재활성.
          final dest =
              kitCurriculumFor(type) != null ? Routes.kitLearn : Routes.control;
          if (context.canPop()) {
            context.pushReplacement(dest);
          } else {
            context.go(dest);
          }
        },
      ),
    );
  }
}
