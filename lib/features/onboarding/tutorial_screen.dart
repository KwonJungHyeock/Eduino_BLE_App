// Author: eduino
// 최초 실행 튜토리얼 — 처음 쓰는 학생·교사에게 앱의 큰 그림을 4장으로 안내(한 번만 노출).
// 사진 없이 커스텀 일러스트/브랜드 마크로 구성.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../widgets/primary_button.dart';
import '../../providers/onboarding_providers.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/kit_illustration.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _page = PageController();
  int _index = 0;

  static const int _count = 4;

  Future<void> _finish() async {
    HapticFeedback.selectionClick();
    await ref.read(tutorialSeenProvider.notifier).markSeen();
    if (!mounted) return;
    context.go(Routes.mode);
  }

  void _next() {
    if (_index >= _count - 1) {
      _finish();
    } else {
      _page.nextPage(
          duration: Motion.base, curve: Motion.emphasized);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: Gap.sm, top: Gap.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('건너뛰기',
                      style: AppType.mono(size: 13, color: AppColors.textMuted)),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Slide(
                    art: _BrandArt(),
                    accent: AppColors.accent,
                    title: '블루투스로 EDUINO를 제어',
                    body: '앱 하나로 RC카와 스마트 교구를\n무선으로 제어하고 체험해요.',
                  ),
                  _Slide(
                    art: _KitArt(KitArt.car),
                    accent: AppColors.signal,
                    title: 'RC카 주행 & 자율',
                    body: '조이스틱·방향·기울기·음성으로 주행하고\n자율주행·라인트레이싱까지.',
                  ),
                  _Slide(
                    art: _KitArt(KitArt.factory),
                    accent: AppColors.signalDeep,
                    title: '스마트 교구 제어',
                    body: '스마트 팩토리·홈·팜을\n서보·릴레이·센서로 제어해요.',
                  ),
                  _Slide(
                    art: _BtArt(),
                    accent: AppColors.mint,
                    title: '블루투스 실습',
                    body: '연결·시리얼 통신·AT 커맨드·LED로\n통신 원리를 직접 배워요.',
                  ),
                ],
              ),
            ),
            // 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: Motion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _index ? AppColors.signal : AppColors.border,
                      borderRadius: Radii.pill,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: PrimaryButton(
                label: _index >= _count - 1 ? '시작하기' : '다음',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.art,
    required this.accent,
    required this.title,
    required this.body,
  });
  final Widget art;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: art,
          ),
          Gap.h24,
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Gap.h12,
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _BrandArt extends StatelessWidget {
  const _BrandArt();
  @override
  Widget build(BuildContext context) => const BrandMark(size: 120);
}

class _KitArt extends StatelessWidget {
  const _KitArt(this.art);
  final KitArt art;
  @override
  Widget build(BuildContext context) =>
      KitIllustration(art: art, size: 132, showTile: false);
}

class _BtArt extends StatelessWidget {
  const _BtArt();
  @override
  Widget build(BuildContext context) => const Icon(Icons.bluetooth_searching,
      size: 96, color: AppColors.mint);
}
