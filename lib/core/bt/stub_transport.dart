// Author: eduino
// 웹 데모용 스텁 전송 — 실제 블루투스 하드웨어 없이 화면·기능 흐름을 확인하는 용도.
// 기본은 no-op(스캔=빈 목록, 연결/전송=무시). BT 패키지를 import 하지 않는다.
//
// 팜 데모(localStorage 'flutter.eduino.demo.farm'=='true') 일 때만 예외적으로:
//   자동 연결 + 온습도/토양 램프값을 incoming 스트림에 주입 → 텔레메트리/씬/
//   코칭/스파크라인이 "연결 후"처럼 실제로 살아 움직인다(Living Twin 실동작 확인).

import 'dart:async';
import 'dart:html' as html;

import 'bt_transport.dart';

class StubTransport implements BtTransport {
  StubTransport() {
    _maybeStartDemo();
  }

  final StreamController<BtConnectionState> _state =
      StreamController<BtConnectionState>.broadcast();
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();

  BtConnectionState _cur = BtConnectionState.disconnected;
  Timer? _demoTimer;
  int _tick = 0;

  @override
  BtModule get module => BtModule.ble;

  @override
  BtConnectionState get state => _cur;

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

  // ── 데모 시뮬레이터(웹) ─────────────────────────────────────────────
  bool _homeMode = false;

  void _maybeStartDemo() {
    var farm = false, factory = false;
    String? home;
    try {
      final ls = html.window.localStorage;
      farm = ls['flutter.eduino.demo.farm'] == 'true';
      factory = ls['flutter.eduino.demo.factory'] == 'true';
      home = ls['flutter.eduino.demo.home'];
    } catch (_) {}
    final homeOn = home != null && home.isNotEmpty;
    if (!farm && !factory && !homeOn) return;
    _homeMode = homeOn;
    final doEmit = farm || homeOn; // 팩토리는 센서 수신 없음(연결만).
    Timer(const Duration(milliseconds: 900), () {
      if (_state.isClosed) return;
      _cur = BtConnectionState.connected;
      _state.add(_cur);
      if (doEmit) {
        _emit();
        _demoTimer =
            Timer.periodic(const Duration(milliseconds: 900), (_) => _emit());
      }
    });
  }

  void _emit() {
    if (_incoming.isClosed) return;
    if (_homeMode) {
      // 홈 — 실내 온·습도 완만한 변동(냉방 느낌).
      final temp = (22 + (_tick % 5)).round(); // 22~26℃
      final humi = (52 + (_tick % 6)).round(); // 52~57%
      _push('$temp,$humi');
    } else {
      // 팜 — 온도↑·토양↓ 드리프트(건강 → 메마름/열기, 코칭 경고 유발).
      final p = (_tick / 14).clamp(0.0, 1.0);
      final temp = (24 + p * 11).round(); // 24 → 35℃
      final humi = (58 + (_tick % 3) * 3).round(); // 58~64%
      final soil = (72 - p * 52).round(); // 72 → 20%
      _push('$temp,$humi');
      _push('$soil%');
    }
    _tick++;
  }

  void _push(String line) => _incoming.add('$line\n'.codeUnits);

  @override
  Future<void> dispose() async {
    _demoTimer?.cancel();
    await _state.close();
    await _incoming.close();
  }
}
