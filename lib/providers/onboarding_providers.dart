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
