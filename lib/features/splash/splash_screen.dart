// Author: eduino
// 인트로 화면 — Eduino AI 로고 (§5.1). 라이트 배경에서 로고를 보여주고 홈으로 자동 전환.
// 로고 파일이 없으면 텍스트 워드마크로 폴백(생성형 데코 아님, §6.4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/app_mode_providers.dart';
import '../../providers/module_providers.dart';

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
    // 온보딩 순서: 모드 선택 → 모듈 선택 → 홈.
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
