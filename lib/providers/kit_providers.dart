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

// ── RC 주행 키트 선택(교구 학습 키트와 독립) ──
// RC 허브(2휠/메탈/4휠)에서 고른 프로파일. 교구 학습 키트와 섞이지 않게 별도 저장.
const String _rcPrefKey = 'eduino.rc.type';

class RcNotifier extends AsyncNotifier<KitProfile?> {
  @override
  Future<KitProfile?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_rcPrefKey);
    if (saved == null) return null;
    final type = KitType.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => KitType.twoWheel,
    );
    if (!KitProfile.rcKits.contains(type)) return null; // RC 타입만 허용
    return KitProfile.forType(type);
  }

  Future<void> select(KitType type) async {
    state = AsyncData(KitProfile.forType(type));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rcPrefKey, type.name);
  }
}

final rcProfileProvider =
    AsyncNotifierProvider<RcNotifier, KitProfile?>(RcNotifier.new);

// ── 라인센서 사용 토글(2휠·메탈: 별매 옵션) ──
// 켜면 라인트레이싱 기능이 컨트롤러에 노출된다. 4휠은 기본 내장이라 항상 노출.
const String _lineSensorKey = 'eduino.rc.lineSensor';

class LineSensorNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lineSensorKey) ?? false;
  }

  Future<void> set(bool v) async {
    state = AsyncData(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lineSensorKey, v);
  }
}

final lineSensorEnabledProvider =
    AsyncNotifierProvider<LineSensorNotifier, bool>(LineSensorNotifier.new);
