// Author: eduino
// 키트 선택 전역 상태. 선택 결과가 사용 가능한 모드/UI 를 결정한다 (차별 C).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/kit/kit_profile.dart';

const String _kitPrefKey = 'eduino.kit.type';

/// 선택된 키트 프로파일. null = 아직 선택 안 함(최초 진입 → 키트 선택 화면).
class KitNotifier extends AsyncNotifier<KitProfile?> {
  @override
  Future<KitProfile?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kitPrefKey);
    if (saved == null) return null;
    final type = KitType.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => KitType.twoWheel,
    );
    return KitProfile.forType(type);
  }

  Future<void> select(KitType type) async {
    state = AsyncData(KitProfile.forType(type));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kitPrefKey, type.name);
  }
}

final kitProfileProvider =
    AsyncNotifierProvider<KitNotifier, KitProfile?>(KitNotifier.new);
