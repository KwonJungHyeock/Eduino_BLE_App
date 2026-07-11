// Author: eduino
// 인트로 화면 — 코드로 그린 EDUINO 브랜드 마크가 "그려지며" 등장(드로우온) 후 자동 전환.
// 사진/로고 파일 없이 CustomPainter(BrandMark)로 브랜드 연출. §6.4 생성형 데코 금지 준수.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/app_mode_providers.dart';
import '../../providers/module_providers.dart';
import '../../providers/onboarding_providers.dart';
import '../../widgets/brand_mark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    // 로고 노출 후, 모듈 선택 여부에 따라 라우팅.
    Future.delayed(const Duration(milliseconds: 1900), _advance);
  }

  Future<void> _advance() async {
    // 온보딩 순서: (최초)튜토리얼 → 모드 선택 → 모듈 선택 → 홈.
    final seenTutorial = await ref.read(tutorialSeenProvider.future);
    if (!mounted) return;
    if (!seenTutorial) {
      context.go(Routes.tutorial);
      return;
    }
    final mode = await ref.read(appModeProvider.future);
    if (!mounted) return;
    if (mode == null) {
      context.go(Routes.mode);
      return;
    }
    final module = await ref.read(moduleProvider.future);
    if (!mounted) return;
    context.go(module == null ? Routes.module : Routes.home);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 인트로는 브랜드 마크가 잘 보이도록 밝은 배경.
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: const _BrandLogo(),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  static const Color _ink = Color(0xFF2B3440);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AnimatedBrandMark(size: 132),
        const SizedBox(height: Gap.lg),
        // 워드마크는 마크가 그려진 뒤 부드럽게 페이드인.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.slow,
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: (t * 1.4 - 0.4).clamp(0.0, 1.0),
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Eduino',
                      style: AppType.mono(
                          size: 38, weight: FontWeight.w800, color: _ink),
                    ),
                    TextSpan(
                      text: ' AI',
                      style: AppType.mono(
                          size: 38,
                          weight: FontWeight.w800,
                          color: AppColors.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AIoT & Coding Education',
                style: AppType.mono(
                  size: 12,
                  color: const Color(0xFF9AA3B0),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
