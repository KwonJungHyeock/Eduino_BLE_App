// Author: eduino
// 교구 학습하기 — 선택한 스마트 교구의 강의자료 커리큘럼을 반영.
// 흐름: ① 소개 → ② 부품·배선(핀표) → ③ 단계별 학습(원문 순서) → ④ 원격 제어(블루투스).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../providers/kit_providers.dart';
import '../../widgets/circuit.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive.dart';
import 'kit_curriculum.dart';
import 'kit_profile.dart';

class KitLearnScreen extends ConsumerWidget {
  const KitLearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final cur = kit == null ? null : kitCurriculumFor(kit.type);

    // 강의 커리큘럼이 아직 없는 교구(홈 등)는 준비중 벽 대신 제어판(집 씬)으로
    // 바로 보낸다(A1). 콘텐츠가 OCR 로 채워지면 커리큘럼이 생겨 학습이 열림.
    if (kit != null && cur == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pushReplacement(Routes.control);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(kit == null ? '교구 학습' : '${_emoji(kit.type)} ${kit.name}'),
      ),
      body: SafeArea(
        child: (kit == null || cur == null)
            ? _fallback(context, kit)
            : ListView(
                padding: pagePadding(context),
                children: [
                  _Hero(cur: cur),
                  Gap.h24,
                  const NodeRailHeader('부품 · 배선', color: AppColors.mint),
                  Gap.h12,
                  _PartsWiring(cur: cur),
                  Gap.h24,
                  NodeRailHeader('단계별 학습 · ${cur.lessons.length}단계',
                      color: AppColors.accent),
                  Gap.h12,
                  for (var i = 0; i < cur.lessons.length; i++) ...[
                    _LessonCard(index: i + 1, lesson: cur.lessons[i]),
                    Gap.h8,
                  ],
                  Gap.h16,
                  const NodeRailHeader('원격 제어 · 블루투스',
                      color: AppColors.signal),
                  Gap.h12,
                  _ControlSection(cur: cur),
                  Gap.h24,
                ],
              ),
      ),
    );
  }

  String _emoji(KitType t) => switch (t) {
        KitType.smartFactory => '🏭',
        KitType.smartHome => '🏠',
        KitType.smartFarm => '🌱',
        _ => '🤖',
      };

  Widget _fallback(BuildContext context, KitProfile? kit) => EmptyState(
        icon: Icons.menu_book_outlined,
        accent: AppColors.accent,
        title: kit == null ? '먼저 교구를 선택하세요' : '학습 자료 준비 중',
        message: kit == null
            ? '스마트 팩토리 · 홈 · 팜 중에서\n보유한 교구를 고르면 학습이 열려요.'
            : '${kit.name} 학습 콘텐츠는 준비 중입니다.\n제어판에서 먼저 제어해 볼 수 있어요.',
        actionLabel: kit == null ? '교구 선택' : '제어판 열기',
        onAction: () =>
            context.push(kit == null ? Routes.kit : Routes.control),
      );
}

// ── ① 소개 히어로 ─────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({required this.cur});
  final KitCurriculum cur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cur.heroColors,
        ),
        borderRadius: Radii.cardLg,
        boxShadow: Shadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cur.heroTitle,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          Gap.h8,
          Text(cur.heroDesc,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.95))),
          Gap.h16,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in cur.heroTags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: Radii.pill,
                  ),
                  child: Text(t,
                      style: AppType.mono(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ② 부품 · 배선 ─────────────────────────────────────────────
class _PartsWiring extends StatelessWidget {
  const _PartsWiring({required this.cur});
  final KitCurriculum cur;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이 키트의 부품',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          Gap.h12,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in cur.parts)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.baseBg,
                    borderRadius: Radii.chip,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: p.color,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                      Gap.w8,
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          Gap.h16,
          Text('배선 (아두이노 핀)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          Gap.h8,
          Container(
            decoration: BoxDecoration(
              borderRadius: Radii.card,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < cur.wiring.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : const Border(
                              top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(cur.wiring[i].part,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: cur.wiring[i].kind.color,
                            borderRadius: Radii.chip,
                          ),
                          child: Text(cur.wiring[i].pin,
                              style: AppType.mono(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: cur.wiring[i].kind == PinKind.i2c
                                      ? const Color(0xFF5A4000)
                                      : Colors.white)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ③ 단계별 학습 (원문 순서) ─────────────────────────────────
class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.index, required this.lesson});
  final int index;
  final KitLesson lesson;

  @override
  Widget build(BuildContext context) {
    final accent = lesson.bluetooth ? AppColors.signal : AppColors.accent;
    return _card(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(lesson.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    if (lesson.bluetooth) ...[
                      Gap.w8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.signal.withValues(alpha: 0.12),
                          borderRadius: Radii.pill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bluetooth,
                                size: 11, color: AppColors.signal),
                            const SizedBox(width: 3),
                            Text('블루투스',
                                style: AppType.mono(
                                    size: 9.5,
                                    weight: FontWeight.w800,
                                    color: AppColors.signal)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Gap.h4,
                Text(lesson.detail,
                    style: AppType.mono(
                        size: 11.5, color: AppColors.textMuted, height: 1.45)),
                if (lesson.examples.isNotEmpty) ...[
                  Gap.h8,
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final e in lesson.examples)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.baseBg,
                            borderRadius: Radii.chip,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(e,
                              style: AppType.mono(
                                  size: 10, color: AppColors.textMuted)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ④ 원격 제어 (블루투스) ────────────────────────────────────
class _ControlSection extends StatelessWidget {
  const _ControlSection({required this.cur});
  final KitCurriculum cur;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('장치 제어',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          Gap.h12,
          Row(
            children: [
              for (var i = 0; i < cur.commands.length; i++) ...[
                if (i > 0) Gap.w8,
                Expanded(child: _CommandTile(cmd: cur.commands[i])),
              ],
            ],
          ),
          Gap.h16,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.signal.withValues(alpha: 0.06),
              borderRadius: Radii.card,
              border: Border.all(color: AppColors.signal.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.signal),
                Gap.w8,
                Expanded(
                  child: Text(cur.btNote,
                      style: AppType.mono(
                          size: 11, color: AppColors.textMuted, height: 1.5)),
                ),
              ],
            ),
          ),
          Gap.h12,
          Pressable(
            onTap: () => context.push(Routes.control),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.signal,
                borderRadius: Radii.card,
                boxShadow: Shadows.glow(AppColors.signal),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth, color: Colors.white, size: 18),
                  Gap.w8,
                  const Text('블루투스 제어판 열기',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.cmd});
  final KitCommand cmd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.baseBg,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cmd.color,
              borderRadius: Radii.chip,
            ),
            child: Icon(cmd.icon, color: Colors.white, size: 20),
          ),
          Gap.h8,
          Text(cmd.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(cmd.command,
              style: AppType.mono(size: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// 공통 카드 컨테이너.
Widget _card({required Widget child, EdgeInsets? padding}) => Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardLg,
        boxShadow: Shadows.soft,
      ),
      child: child,
    );
