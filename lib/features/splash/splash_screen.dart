// Author: eduino
// 스플래시 — 저장된 키트 선택을 로드해 다음 화면을 결정 (§5.1). 장식 없이 브랜드 워드마크만.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/kit_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = ref.watch(kitProfileProvider);

    // 로드 완료 시 라우팅(빌드 후 1회).
    kit.whenData((profile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final loc = GoRouterState.of(context).uri.path;
        if (loc != Routes.splash) return;
        context.go(profile == null ? Routes.kit : Routes.connect);
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EDUINO',
                style: AppType.mono(
                  size: 34,
                  weight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 6,
                )),
            Gap.h8,
            Text('RC · NEO COCKPIT',
                style: AppType.mono(
                  size: 12,
                  color: AppColors.accent,
                  letterSpacing: 4,
                )),
            const SizedBox(height: Gap.xl),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.signal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
