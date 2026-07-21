// Author: eduino
// 시리얼 채팅 빠른 문장(프리셋) — 편집 가능(추가/삭제), 로컬 저장.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefKey = 'eduino.serialPresets';
const List<String> _defaults = ['안녕하세요', 'hello', 'LED ON', 'LED OFF', '1', '0'];

class SerialPresetsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_prefKey) ?? List<String>.from(_defaults);
  }

  Future<void> _save(List<String> list) async {
    state = AsyncData(list);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_prefKey, list);
  }

  Future<void> add(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final cur = state.valueOrNull ?? _defaults;
    if (cur.contains(t)) return;
    await _save([...cur, t]);
  }

  Future<void> remove(String text) async {
    final cur = state.valueOrNull ?? _defaults;
    await _save(cur.where((e) => e != text).toList());
  }
}

final serialPresetsProvider =
    AsyncNotifierProvider<SerialPresetsNotifier, List<String>>(
        SerialPresetsNotifier.new);
