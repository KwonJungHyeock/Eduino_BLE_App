// Author: eduino
// 웹 데모용 스텁 전송 — 실제 블루투스 하드웨어 없이 화면·기능 흐름을 확인하는 용도.
// 모든 동작은 no-op(스캔=빈 목록, 연결/전송=무시). BT 패키지를 import 하지 않는다.

import 'dart:async';

import 'bt_transport.dart';

class StubTransport implements BtTransport {
  final StreamController<BtConnectionState> _state =
      StreamController<BtConnectionState>.broadcast();
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();

  @override
  BtModule get module => BtModule.ble;

  @override
  BtConnectionState get state => BtConnectionState.disconnected;

  @override
  Stream<BtConnectionState> get stateStream => _state.stream;

  @override
  BtDevice? get connectedDevice => null;

  @override
  Stream<List<BtDevice>> scan(
          {Duration timeout = const Duration(seconds: 8)}) =>
      Stream.value(const <BtDevice>[]);

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(BtDevice device) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> send(List<int> bytes) async {}

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> dispose() async {
    await _state.close();
    await _incoming.close();
  }
}
