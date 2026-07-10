// Author: eduino
// 인트로 화면 — Eduino AI 로고 (§5.1). 라이트 배경에서 로고를 보여주고 홈으로 자동 전환.
// 로고 파일이 없으면 텍스트 워드마크로 폴백(생성형 데코 아님, §6.4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/kit_providers.dart';

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
    // 저장된 키트 로드를 미리 트리거(홈 진입 시 반영).
    ref.read(kitProfileProvider);
    // 로고 노출 후 홈으로 전환.
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 인트로는 로고가 잘 보이도록 밝은 배경.
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          child: Image.asset(
            'assets/brand/eduino_ai_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const _WordmarkFallback(),
          ),
        ),
      ],
    );
  }
}

/// 로고 파일이 없을 때 쓰는 타이포 폴백. 실제 로고 색(다크 텍스트 + EDUINO 레드) 톤 유지.
class _WordmarkFallback extends StatelessWidget {
  const _WordmarkFallback();

  static const Color _ink = Color(0xFF2B3440);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Eduino',
                style: AppType.mono(
                    size: 40, weight: FontWeight.w800, color: _ink),
              ),
              TextSpan(
                text: ' AI',
                style: AppType.mono(
                    size: 40,
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
    );
  }
}
