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
      _lastCmd = null; // 재연결 시 첫 명령이 항상 전송되도록 초기화(안전).
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
    _aux.cancel();
    for (final t in _prm.values) {
      t.cancel();
    }
  }

  // ---- 기본 RC 단일 문자 명령 (조이스틱/방향/틸트/음성 공통) -----------------

  DriveCmd? _lastCmd;

  /// 단일 문자 주행 명령(g/b/l/r/q/w/s). 같은 명령 반복은 억제(스로틀링) —
  /// 래치형 펌웨어(다음 명령까지 유지)라 매 프레임 재전송하지 않는다.
  void driveCmd(DriveCmd cmd) {
    if (cmd == _lastCmd) return;
    _lastCmd = cmd;
    _sendChar(cmd.code);
  }

  /// 안전 정지 — 손 떼기/중립/화면 이탈 시. 중복 억제와 무관하게 무조건 s 전송.
  void driveStop() {
    _cancelThrottlers();
    _lastCmd = DriveCmd.stop;
    _sendChar('s');
  }

  /// 단일 문자 전송(개행 없음) + 보이는 통신 로그.
  void _sendChar(String ch) {
    if (!_connected) return;
    _ref.read(transportProvider).send(utf8.encode(ch));
    _ref.read(terminalProvider.notifier).logOutgoing(ch);
  }

  // ---- 확장 펌웨어 트랙 (속도/아날로그/자율/라인 — 라인 프로토콜) -------------

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

  /// LED ON/OFF (기본 핀).
  void ledOnOff(bool on) => _sendFrame(Commands.ledOnOff(on));

  /// LED ON/OFF (커스텀 핀).
  void led(int pin, bool on) => _sendFrame(Commands.led(pin, on));

  /// LED RGB (네오픽셀).
  void ledRgb(int r, int g, int b) => _sendFrame(Commands.ledRgb(r, g, b));

  // ---- 교구(비주행) 액추에이터 --------------------------------------------

  final _Throttler _aux = _Throttler(const Duration(milliseconds: 100));

  /// 서보 각도(0-180). 슬라이더용 스로틀링.
  void setServo(int id, int angle) {
    _aux.run(() => _sendFrame(Commands.servo(id, angle)));
  }

  /// 릴레이/액추에이터 ON/OFF(팬·펌프·조명·컨베이어). 즉시.
  void setActuator(int id, bool on) => _sendFrame(Commands.actuator(id, on));

  /// 액추에이터 세기(PWM %). 슬라이더용 스로틀링.
  void setActuatorPwm(int id, int percent) {
    _aux.run(() => _sendFrame(Commands.actuatorPwm(id, percent)));
  }

  /// LCD 텍스트 전송.
  void sendLcd(int line, String text) => _sendFrame(Commands.lcd(line, text));

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
