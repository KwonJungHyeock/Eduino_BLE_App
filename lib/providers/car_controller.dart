// Author: eduino
// 모든 주행 명령의 유일한 전송 지점 (강제 규칙). 송신 스로틀링 + 연결 상태 가드 + 하트비트 내장.
// 화면은 raw transport.send() 를 절대 부르지 않고 이 컨트롤러만 호출한다.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bt/bt_transport.dart';
import '../core/protocol/commands.dart';
import '../features/kit/kit_controls.dart';
import 'app_mode_providers.dart';
import 'bt_providers.dart';
import 'kit_providers.dart';

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

  // §4.4 송신 스로틀링: 조이스틱/틸트 ~20Hz.
  final _Throttler _drive = _Throttler(const Duration(milliseconds: 50));
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
      _kitInit(); // 교구 초기화(팩토리 's' 등) 자동 전송.
    } else {
      _stopHeartbeat();
      _cancelThrottlers();
      _lastCmd = null; // 재연결 시 첫 명령이 항상 전송되도록 초기화(안전).
    }
  }

  /// 연결 직후 교구 초기화 문자 전송(데이터 주도 · 팩토리 's').
  void _kitInit() {
    final kit = _ref.read(kitProfileProvider).valueOrNull;
    final init = kit == null ? null : kitControlsFor(kit.type)?.initChar;
    if (init == null) return;
    Timer(const Duration(milliseconds: 300), () {
      if (_connected) kitChar(init);
    });
  }

  // 교육용 시리얼 채팅/AT 터미널 화면에서는 RC 주행 하트비트(PNG:)를 억제한다.
  // 하트비트는 주행 안전 전용이며, "보이는 통신" 교보재 화면의 실제 송신을 오염시키면 안 된다.
  int _hbPauseCount = 0;

  /// PNG 하트비트 허용 여부.
  ///  · 화면 진입 억제(pause) 중이면 금지.
  ///  · 블루투스 실습(lab) 모드는 RC 주행이 없으므로 절대 전송 금지 —
  ///    시리얼/AT 실습 중 보드(아두이노 IDE)에 PNG 가 쏟아지지 않게 한다.
  bool get _heartbeatAllowed {
    if (_hbPauseCount != 0) return false;
    if (_ref.read(appModeProvider).valueOrNull == AppMode.lab) return false;
    return true;
  }

  /// 하트비트 일시 중단(화면 진입 시). 중첩 진입 대비 카운트 기반.
  void pauseHeartbeat() {
    _hbPauseCount++;
    _stopHeartbeat();
  }

  /// 하트비트 재개(화면 이탈 시). 억제가 모두 풀리고 연결 중이면 재시작.
  void resumeHeartbeat() {
    if (_hbPauseCount > 0) _hbPauseCount--;
    if (_heartbeatAllowed && _connected) _startHeartbeat();
  }

  void _startHeartbeat() {
    if (!_heartbeatAllowed) return; // 억제 중이면 재연결로 다시 시작되지 않도록 가드.
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      // 도중에 실습 모드로 전환/억제되면 즉시 중단(PNG 유출 방지).
      if (!_heartbeatAllowed) {
        _stopHeartbeat();
        return;
      }
      _sendRaw(Commands.ping(), silent: true); // 하트비트는 터미널 스팸 방지 위해 미표시.
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void _cancelThrottlers() {
    _drive.cancel();
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

  // ---- 교구(스마트킷) 명령 — 데이터 주도 commandMap 이 문자를 결정 ---------

  /// 교구 단일 문자 명령(토글/프리셋). 전송 + "보이는 통신" 로그.
  void kitChar(String ch) => _sendChar(ch);

  /// 교구 네오픽셀 RGB — R,G,B 3바이트 전송(레거시). 로그는 "R,G,B".
  void kitRgb(int r, int g, int b) {
    if (!_connected) return;
    _ref.read(transportProvider).send([r & 0xFF, g & 0xFF, b & 0xFF]);
    _ref.read(terminalProvider.notifier).logOutgoing('$r,$g,$b');
  }

  /// 교구 텍스트 라인 명령 — 팜 통합 펌웨어 규약(FAN:1 / LED:r,g,b 등). text + \n 전송.
  /// raw 바이트와 텍스트 혼용 금지(QA 0-5) — 팜/홈 텍스트 라인은 이 경로로만.
  void kitLine(String line) {
    if (!_connected) return;
    final frame = line.endsWith('\n') ? line : '$line\n';
    _ref.read(transportProvider).send(utf8.encode(frame));
    _ref.read(terminalProvider.notifier).logOutgoing(line);
  }

  /// 모니터 요청 바이트(홈 온습도 0x00 등). 주기 타이머에서 호출.
  void kitRequest(List<int> bytes, {String log = '요청'}) {
    if (!_connected) return;
    _ref.read(transportProvider).send(bytes);
    _ref.read(terminalProvider.notifier).logOutgoing(log);
  }

  // ---- 확장 펌웨어 트랙 (속도/아날로그/자율/라인 — 라인 프로토콜) -------------

  /// 조이스틱/드라이브: throttle/steer -100..100. 스로틀링됨.
  void drive(int throttle, int steer) {
    _drive.run(() => _sendFrame(Commands.drive(throttle, steer)));
  }

  /// 방향 버튼. press/release 즉시 전송(스로틀 없음).
  void move(MoveDir dir) => _sendFrame(Commands.move(dir));

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
