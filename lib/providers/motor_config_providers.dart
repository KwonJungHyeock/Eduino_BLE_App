// Author: eduino
// 모터 포트 매핑(Adafruit Motor Shield M1~M4). 키트별로 논리 바퀴 → 실제 포트를 저장.
// 앱은 이 매핑을 저장·표시하고, 펌웨어가 같은 매핑을 쓰도록 가이드한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/kit/kit_profile.dart';

enum MotorPort { m1, m2, m3, m4 }

extension MotorPortLabel on MotorPort {
  String get label => name.toUpperCase(); // M1..M4
}

/// 키트별 논리 바퀴 라벨(4휠은 4개, 그 외 좌/우).
List<String> motorSlotLabels(KitType t) => t == KitType.fourWheel
    ? const ['앞 왼쪽', '앞 오른쪽', '뒤 왼쪽', '뒤 오른쪽']
    : const ['왼쪽 바퀴', '오른쪽 바퀴'];

/// 기본 포트 매핑(사용자 배선 기준: 2휠 좌=M1, 우=M4).
List<MotorPort> defaultMotorPorts(KitType t) => t == KitType.fourWheel
    ? const [MotorPort.m1, MotorPort.m2, MotorPort.m3, MotorPort.m4]
    : const [MotorPort.m1, MotorPort.m4];

String _key(KitType t) => 'eduino.motor.${t.name}';

class MotorConfigNotifier extends AsyncNotifier<Map<KitType, List<MotorPort>>> {
  @override
  Future<Map<KitType, List<MotorPort>>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <KitType, List<MotorPort>>{};
    for (final t in KitType.values) {
      final saved = prefs.getString(_key(t));
      if (saved == null) {
        map[t] = defaultMotorPorts(t);
      } else {
        map[t] = saved
            .split(',')
            .map((s) => MotorPort.values.firstWhere(
                  (p) => p.name == s,
                  orElse: () => MotorPort.m1,
                ))
            .toList();
      }
    }
    return map;
  }

  List<MotorPort> portsFor(KitType t) =>
      state.valueOrNull?[t] ?? defaultMotorPorts(t);

  Future<void> setPort(KitType kit, int slot, MotorPort port) async {
    final current = Map<KitType, List<MotorPort>>.from(state.valueOrNull ?? {});
    final list = List<MotorPort>.from(current[kit] ?? defaultMotorPorts(kit));
    if (slot < 0 || slot >= list.length) return;
    list[slot] = port;
    current[kit] = list;
    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(kit), list.map((p) => p.name).join(','));
  }
}

final motorConfigProvider =
    AsyncNotifierProvider<MotorConfigNotifier, Map<KitType, List<MotorPort>>>(
        MotorConfigNotifier.new);
