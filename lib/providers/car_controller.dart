// Author: eduino
// 모든 주행 명령의 유일한 전송 지점 (강제 규칙). 송신 스로틀링 + 연결 상태 가드 + 하트비트 내장.
// 화면은 raw transport.send() 를 절대 부르지 않고 이 컨트롤러만 호출한다.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bt/bt_transport.dart';
import '../core/protocol/commands.dart';
import 'bt_providers.dart';

/// 연속 스트림 명령(조이스틱/틸트/슬라이더)을 초당 N회로 제한하는 리딩+트레일링 스로틀러.
class _Throttler {
  _Throttler(this.interval);
  final Duration interval;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _timer;

  void run(VoidCallback action) {
    final now = DateTime.now();
    final elapsed = now.difference(_last);
    if (elapsed >= interval) {
      _timer?.cancel();
      _last = now;
      action();
    } else {
      // 최신값만 트레일링 전송 → 대역폭 절약, 마지막 입력 보장.
      _timer?.cancel();
      _timer = Timer(interval - elapsed, () {
        _last = DateTime.now();
        action();
      });
    }
  }

  void cancel() => _timer?.cancel();
}

class CarController {
  CarController(this._ref);
  final Ref _ref;

  // §4.4 송신 스로틀링: 조이스틱/틸트 ~20Hz, 슬라이더 ~10Hz.
  final _Throttler _drive = _Throttler(const Duration(milliseconds: 50));
  final _Throttler _speedCap = _Throttler(const Duration(milliseconds: 100));
  final Map<PrmKey, _Throttler> _prm = {
    for (final k in PrmKey.values) k: _Throttler(const Duration(milliseconds: 100)),
  };

  // 하트비트: 250ms 주기(펌웨어 500ms 타임아웃 대비 여유). 연결 중에만 동작.
  Timer? _heartbeat;
  static const Duration _heartbeatInterval = Duration(milliseconds: 250);

  bool get _connected =>
      _ref.read(transportProvider).state == BtConnectionState.connected;

  // ---- 연결 수명 관리 -------------------------------------------------------

  void onConnectionChanged(BtConnectionState s) {
    if (s == BtConnectionState.connected) {
      _startHeartbeat();
    } else {
      _stopHeartbeat();
      _cancelThrottlers();
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      _sendRaw(Commands.ping(), silent: true); // 하트비트는 터미널 스팸 방지 위해 미표시.
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void _cancelThrottlers() {
    _drive.cancel();
    _speedCap.cancel();
    for (final t in _prm.values) {
      t.cancel();
    }
  }

  // ---- 명령 API (화면이 호출) ----------------------------------------------

  /// 조이스틱/드라이브: throttle/steer -100..100. 스로틀링됨.
  void drive(int throttle, int steer) {
    _drive.run(() => _sendFrame(Commands.drive(throttle, steer)));
  }

  /// 방향 버튼. press/release 즉시 전송(스로틀 없음).
  void move(MoveDir dir) => _sendFrame(Commands.move(dir));

  /// 속도 상한(%). 스로틀링됨.
  void setSpeedCap(int percent) {
    _speedCap.run(() => _sendFrame(Commands.speedCap(percent)));
  }

  /// 즉시 정지(안전). 대기 중 스로틀 전송 취소 후 STP 즉시.
  void stop() {
    _cancelThrottlers();
    _sendFrame(Commands.stop());
  }

  /// 자율↔수동 모드 전환.
  void setMode(DriveMode mode) => _sendFrame(Commands.mode(mode));

  /// 파라미터 튜닝(키별 스로틀링).
  void setParam(PrmKey key, int value) {
    _prm[key]!.run(() => _sendFrame(Commands.param(key, value)));
  }

  /// LED ON/OFF (P6 화면 이전에도 사용 가능하도록 API 제공).
  void ledOnOff(bool on) => _sendFrame(Commands.ledOnOff(on));

  /// 터미널 원문 전송(RAW: 프로토콜 프레임).
  void raw(String text) => _sendFrame(Commands.raw(text));

  /// 시리얼 채팅용 — 프로토콜 프레임 없이 입력 문자열 그대로 + 개행 전송.
  /// (아두이노 SoftwareSerial.readStringUntil('\n') 예제와 짝을 이룸)
  void sendPlain(String text) {
    if (!_connected) return;
    final t = text.endsWith('\n') ? text : '$text\n';
    _ref.read(transportProvider).send(utf8.encode(t));
    _ref.read(terminalProvider.notifier).logOutgoing(text);
  }

  /// 백그라운드/끊김 전환 시 안전 정지 (§4.4). 하트비트도 정지.
  void emergencyStop() {
    _cancelThrottlers();
    _sendFrame(Commands.stop());
  }

  // ---- 내부 전송 ------------------------------------------------------------

  void _sendFrame(String frame, {bool silent = false}) {
    // 연결 상태 가드 — 미연결이면 조용히 무시(전송 실패로 화면이 깨지지 않게).
    if (!_connected) return;
    _ref.read(transportProvider).send(Commands.encode(frame));
    if (!silent) _ref.read(terminalProvider.notifier).logOutgoing(frame);
  }

  void _sendRaw(String frame, {bool silent = false}) =>
      _sendFrame(frame, silent: silent);

  void dispose() {
    _stopHeartbeat();
    _cancelThrottlers();
  }
}

/// CarController 는 연결 상태를 구독해 하트비트를 자동 관리한다.
final carControllerProvider = Provider<CarController>((ref) {
  final controller = CarController(ref);
  ref.listen<BtConnectionState>(
    connectionProvider,
    (prev, next) => controller.onConnectionChanged(next),
    fireImmediately: true,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
