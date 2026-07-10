// Author: eduino
// 마지막으로 연결한 기기를 기억한다(자동/빠른 재연결용). 수업 중 매번 스캔하는 번거로움 제거.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/bt/bt_transport.dart';

class LastDevice {
  const LastDevice({required this.id, required this.name, required this.module});
  final String id;
  final String name;
  final BtModule module;

  BtDevice toDevice() =>
      BtDevice(id: id, name: name, module: module, isKnownModule: true);
}

const String _kId = 'eduino.last.id';
const String _kName = 'eduino.last.name';
const String _kModule = 'eduino.last.module';

class LastDeviceNotifier extends AsyncNotifier<LastDevice?> {
  @override
  Future<LastDevice?> build() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_kId);
    if (id == null) return null;
    final mod = BtModule.values.firstWhere(
      (m) => m.name == (p.getString(_kModule) ?? 'ble'),
      orElse: () => BtModule.ble,
    );
    return LastDevice(id: id, name: p.getString(_kName) ?? id, module: mod);
  }

  Future<void> save(BtDevice device) async {
    final d = LastDevice(
        id: device.id, name: device.displayName, module: device.module);
    state = AsyncData(d);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, d.id);
    await p.setString(_kName, d.name);
    await p.setString(_kModule, d.module.name);
  }

  Future<void> clear() async {
    state = const AsyncData(null);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
    await p.remove(_kName);
    await p.remove(_kModule);
  }
}

final lastDeviceProvider =
    AsyncNotifierProvider<LastDeviceNotifier, LastDevice?>(
        LastDeviceNotifier.new);
