// Author: eduino
// App → Car 명령 인코더 (§4.2). 라인 기반 ASCII: <CMD>:<arg1>,<arg2>,...\n
// "보이는 통신" = 교보재. BLE 20바이트 고려해 짧게 유지.

import 'dart:convert';

/// 방향 버튼 8방향 + 정지 (§4.2 MOV).
enum MoveDir { f, b, l, r, fl, fr, bl, br, s }

extension MoveDirCode on MoveDir {
  String get code {
    switch (this) {
      case MoveDir.f:
        return 'F';
      case MoveDir.b:
        return 'B';
      case MoveDir.l:
        return 'L';
      case MoveDir.r:
        return 'R';
      case MoveDir.fl:
        return 'FL';
      case MoveDir.fr:
        return 'FR';
      case MoveDir.bl:
        return 'BL';
      case MoveDir.br:
        return 'BR';
      case MoveDir.s:
        return 'S';
    }
  }
}

/// 주행 모드 (§4.2 MOD).
enum DriveMode { manual, auto }

extension DriveModeCode on DriveMode {
  String get code => this == DriveMode.auto ? 'AUTO' : 'MANUAL';
}

/// PRM 튜닝 키 (§4.2). LINE=라인민감도0-100 / DIST=장애물 임계cm / SPD=자율속도0-100.
enum PrmKey { line, dist, spd }

extension PrmKeyCode on PrmKey {
  String get code {
    switch (this) {
      case PrmKey.line:
        return 'LINE';
      case PrmKey.dist:
        return 'DIST';
      case PrmKey.spd:
        return 'SPD';
    }
  }
}

/// 명령을 프로토콜 문자열로 인코딩(개행 포함). 실제 전송은 [encode].
abstract class Commands {
  /// 드라이브/조이스틱: throttle/steer 는 -100..100.
  static String drive(int throttle, int steer) =>
      'DRV:${_clamp(throttle)},${_clamp(steer)}';

  /// 방향 버튼.
  static String move(MoveDir dir) => 'MOV:${dir.code}';

  /// 속도 상한 캡 (%): 0..100.
  static String speedCap(int percent) => 'SPD:${_clamp(percent, 0, 100)}';

  /// 즉시 정지(안전).
  static String stop() => 'STP:';

  /// LED ON/OFF.
  static String ledOnOff(bool on) => 'LED:${on ? 1 : 0}';

  /// LED RGB (네오픽셀).
  static String ledRgb(int r, int g, int b) =>
      'LED:${_clamp(r, 0, 255)},${_clamp(g, 0, 255)},${_clamp(b, 0, 255)}';

  /// 자율↔수동 모드 전환.
  static String mode(DriveMode mode) => 'MOD:${mode.code}';

  /// 파라미터 튜닝.
  static String param(PrmKey key, int value) => 'PRM:${key.code},$value';

  /// 하트비트.
  static String ping() => 'PNG:';

  /// AT 패스스루(터미널 원문).
  static String raw(String text) => 'RAW:$text';

  /// 프로토콜 문자열 → 전송 바이트(개행 부착, UTF-8). 이미 \n 로 끝나면 중복 부착 안 함.
  static List<int> encode(String frame) {
    final withNewline = frame.endsWith('\n') ? frame : '$frame\n';
    return utf8.encode(withNewline);
  }

  static int _clamp(int v, [int lo = -100, int hi = 100]) =>
      v < lo ? lo : (v > hi ? hi : v);
}
