// Author: eduino
// 통신 모듈 선택(HM-10 BLE / HC-06 Classic SPP) 전역 상태. 시작 시 선택해 앱 동작을 맞춘다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/bt/bt_transport.dart';

const String _modulePrefKey = 'eduino.module';

/// 선택된 통신 모듈. null = 아직 선택 안 함(시작 시 모듈 선택 화면).
class ModuleNotifier extends AsyncNotifier<BtModule?> {
  @override
  Future<BtModule?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modulePrefKey);
    if (saved == null) return null;
    return BtModule.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => BtModule.ble,
    );
  }

  Future<void> select(BtModule module) async {
    state = AsyncData(module);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modulePrefKey, module.name);
  }
}

final moduleProvider =
    AsyncNotifierProvider<ModuleNotifier, BtModule?>(ModuleNotifier.new);

extension BtModuleLabel on BtModule {
  String get title => this == BtModule.ble ? 'HM-10 (BLE)' : 'HC-06 (Classic)';
  String get shortName => this == BtModule.ble ? 'HM-10' : 'HC-06';
}
