// Author: eduino
// 온보딩 상태 — 최초 실행 튜토리얼을 봤는지 기억(한 번만 노출).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialSeenNotifier extends AsyncNotifier<bool> {
  static const _key = 'eduino.tutorial.seen';

  @override
  Future<bool> build() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    state = const AsyncData(true);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}

final tutorialSeenProvider =
    AsyncNotifierProvider<TutorialSeenNotifier, bool>(TutorialSeenNotifier.new);

// 키트별 '학습(수업 안내) 페이지를 봤는지' — 처음만 학습, 이후 제어판 직행(QA A).
// 값은 KitType.name 문자열 집합. 재열람 진입점(제어판 '수업 안내')은 별도로 유지.
class LearnSeenNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'eduino.learn.seen';

  @override
  Future<Set<String>> build() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? const <String>[]).toSet();
  }

  /// 해당 키트 타입을 '학습 봤음'으로 기록(멱등). prefs 를 진실원으로 읽어
  /// 로딩 중 호출돼도 기존 기록이 유실되지 않게 한다.
  Future<void> markSeen(String typeName) async {
    final p = await SharedPreferences.getInstance();
    final cur = (p.getStringList(_key) ?? const <String>[]).toSet();
    if (!cur.add(typeName)) return; // 이미 기록됨
    await p.setStringList(_key, cur.toList());
    state = AsyncData(cur);
  }
}

final learnSeenProvider =
    AsyncNotifierProvider<LearnSeenNotifier, Set<String>>(
  LearnSeenNotifier.new,
);
