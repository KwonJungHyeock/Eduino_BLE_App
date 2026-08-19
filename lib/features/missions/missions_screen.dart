// Author: eduino
// 미션·챌린지 (§5.8): 랩타임 스톱워치 + 개인 베스트(로컬 저장).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/orientation_fill.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _Challenge {
  const _Challenge(this.id, this.title, this.desc);
  final String id;
  final String title;
  final String desc;
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  static const List<_Challenge> _challenges = [
    _Challenge('obstacle', '장애물 코스 랩타임', '초음파로 벽을 피하며 한 바퀴 최단 기록'),
    _Challenge('line', '라인트레이싱 완주', '검은 선을 따라 완주 시간 측정'),
    _Challenge('free', '자유 주행', '원하는 코스로 기록 도전'),
  ];

  int _index = 0;
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;
  Map<String, int> _best = {};

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, int>{};
    for (final c in _challenges) {
      final v = prefs.getInt('eduino.best.${c.id}');
      if (v != null) map[c.id] = v;
    }
    if (mounted) setState(() => _best = map);
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_sw.isRunning) {
      _sw.stop();
      _ticker?.cancel();
      _saveIfBest();
    } else {
      _sw.reset();
      _sw.start();
      _ticker = Timer.periodic(
          const Duration(milliseconds: 50), (_) => setState(() {}));
    }
    setState(() {});
  }

  Future<void> _saveIfBest() async {
    final id = _challenges[_index].id;
    final ms = _sw.elapsedMilliseconds;
    if (ms <= 0) return;
    final prev = _best[id];
    if (prev == null || ms < prev) {
      setState(() => _best = {..._best, id: ms});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('eduino.best.$id', ms);
    }
  }

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    final cs = (ms % 1000) ~/ 10;
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ch = _challenges[_index];
    final running = _sw.isRunning;
    final best = _best[ch.id];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: OrientationFillColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 챌린지 선택
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _challenges.length; i++)
                  ChoiceChip(
                    label: Text(_challenges[i].title.split(' ').first),
                    selected: i == _index,
                    onSelected: running
                        ? null
                        : (_) => setState(() => _index = i),
                    selectedColor: AppColors.signal,
                    labelStyle: AppType.mono(
                        size: 12,
                        color:
                            i == _index ? Colors.white : AppColors.textPrimary),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  ),
              ],
            ),
            Gap.h16,
            SurfaceCard(
              child: Column(
                children: [
                  Text(ch.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Gap.h4,
                  Text(ch.desc,
                      textAlign: TextAlign.center,
                      style: AppType.mono(
                          size: 12, color: AppColors.textMuted)),
                  Gap.h24,
                  Text(_fmt(_sw.elapsedMilliseconds),
                      style: AppType.instrument(size: 56)),
                  Gap.h8,
                  Text(best == null ? '베스트 —' : '베스트 ${_fmt(best)}',
                      style: AppType.mono(
                          size: 13, color: AppColors.signalDeep)),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: running ? '기록 종료' : '시작',
              icon: running ? Icons.flag : Icons.play_arrow,
              color: running ? AppColors.accent : AppColors.signal,
              height: 60,
              expand: false,
              onPressed: _toggle,
            ),
          ],
        ),
      ),
    );
  }
}
