// Author: eduino
// Car → App 텔레메트리 디코더 (§4.3) + Notify 조각 재조립 (§9.2).

import 'dart:convert';

import 'commands.dart';

/// 파싱된 텔레메트리 이벤트(1개 라인 → 1개 이벤트).
sealed class TelemetryEvent {
  const TelemetryEvent();
}

/// 초음파 거리(cm) — DST:<cm>
class DistanceEvent extends TelemetryEvent {
  const DistanceEvent(this.cm);
  final int cm;
}

/// IR 라인센서 3채널 — LIN:<l>,<c>,<r> (0/1 또는 아날로그).
class LineSensorEvent extends TelemetryEvent {
  const LineSensorEvent(this.left, this.center, this.right);
  final int left;
  final int center;
  final int right;
}

/// 모드 응답 — MOD:<AUTO/MANUAL>
class ModeEvent extends TelemetryEvent {
  const ModeEvent(this.mode);
  final DriveMode mode;
}

/// 배터리(%) — BAT:<pct>
class BatteryEvent extends TelemetryEvent {
  const BatteryEvent(this.percent);
  final int percent;
}

/// 수신 확인 — ACK:<cmd>
class AckEvent extends TelemetryEvent {
  const AckEvent(this.cmd);
  final String cmd;
}

/// 로그(터미널 표시) — LOG:<text>
class LogEvent extends TelemetryEvent {
  const LogEvent(this.text);
  final String text;
}

/// 범용 센서값 — SEN:<key>,<value> (온습도·토양·조도·물체감지 등 교구 공통).
class SensorEvent extends TelemetryEvent {
  const SensorEvent(this.key, this.value);
  final String key; // 예: TMP, HUM, SOL, LUX, OBJ
  final double value;
}

/// 알 수 없는/파싱 실패 라인(원문 보존, 터미널엔 그대로 표시).
class UnknownEvent extends TelemetryEvent {
  const UnknownEvent(this.raw);
  final String raw;
}

/// 교구(팜/홈) 모니터링 라인 파싱 — 실제 통합 펌웨어 규약(prefix 필수, QA 0-1/0-2).
///   SOIL:<0~100>     → [SOL]
///   TH:<온도>,<습도>  → [TMP, HUM]   (예: TH:27,60)
/// prefix 로 라우팅해 SOIL·TH 가 섞여 깨지지 않게 한다. 수신값은 SensorEvent 로 반환.
List<SensorEvent> parseMonitorText(String line) {
  final t = line.trim();
  if (t.isEmpty) return const [];
  final c = t.indexOf(':');
  if (c < 0) return const [];
  final key = t.substring(0, c).trim().toUpperCase();
  final arg = t.substring(c + 1).trim();
  switch (key) {
    case 'SOIL':
      final v =
          double.tryParse(arg.endsWith('%') ? arg.substring(0, arg.length - 1).trim() : arg);
      return v == null ? const [] : [SensorEvent('SOL', v)];
    case 'TH':
      final p = arg.split(',');
      if (p.length < 2) return const [];
      final temp = double.tryParse(p[0].trim());
      final humi = double.tryParse(p[1].trim());
      final out = <SensorEvent>[];
      if (temp != null) out.add(SensorEvent('TMP', temp));
      if (humi != null) out.add(SensorEvent('HUM', humi));
      return out;
    default:
      return const [];
  }
}

/// 팩토리 단일문자 회신 — 라인 없음(개행 무관). 각 바이트를 이벤트로 처리(QA 0-3/0-5).
///   y/n = 가동/정지 상태 · r/g/b = 물체 1개 분류될 때마다 그 색.
enum FactoryChar { running, stopped, sortRed, sortGreen, sortBlue, none }

FactoryChar decodeFactoryChar(int byte) {
  switch (byte) {
    case 0x79: // 'y'
      return FactoryChar.running;
    case 0x6E: // 'n'
      return FactoryChar.stopped;
    case 0x72: // 'r'
      return FactoryChar.sortRed;
    case 0x67: // 'g'
      return FactoryChar.sortGreen;
    case 0x62: // 'b'
      return FactoryChar.sortBlue;
    default:
      return FactoryChar.none;
  }
}

abstract class TelemetryDecoder {
  /// 한 줄(개행 제외) → 이벤트. 형식 오류는 UnknownEvent 로 보존.
  static TelemetryEvent decode(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const UnknownEvent('');
    final c = trimmed.indexOf(':');
    if (c < 0) return UnknownEvent(trimmed);

    final key = trimmed.substring(0, c).toUpperCase();
    final arg = trimmed.substring(c + 1);

    switch (key) {
      case 'DST':
        final v = int.tryParse(arg.trim());
        return v == null ? UnknownEvent(trimmed) : DistanceEvent(v);
      case 'LIN':
        final parts = arg.split(',');
        if (parts.length < 3) return UnknownEvent(trimmed);
        final l = int.tryParse(parts[0].trim());
        final cc = int.tryParse(parts[1].trim());
        final r = int.tryParse(parts[2].trim());
        if (l == null || cc == null || r == null) return UnknownEvent(trimmed);
        return LineSensorEvent(l, cc, r);
      case 'MOD':
        final u = arg.trim().toUpperCase();
        final m = u == 'AUTO'
            ? DriveMode.auto
            : u == 'LINE'
                ? DriveMode.line
                : DriveMode.manual;
        return ModeEvent(m);
      case 'BAT':
        final v = int.tryParse(arg.trim());
        return v == null ? UnknownEvent(trimmed) : BatteryEvent(v);
      case 'ACK':
        return AckEvent(arg.trim());
      case 'LOG':
        return LogEvent(arg);
      case 'SEN':
        final parts = arg.split(',');
        if (parts.length < 2) return UnknownEvent(trimmed);
        final v = double.tryParse(parts[1].trim());
        return v == null
            ? UnknownEvent(trimmed)
            : SensorEvent(parts[0].trim().toUpperCase(), v);
      default:
        return UnknownEvent(trimmed);
    }
  }
}

/// Notify 조각(바이트)들을 모아 \n 기준으로 완전한 라인만 방출 (§9.2).
/// HM-10 은 20바이트 단위로 조각나 도착할 수 있으므로 반드시 재조립.
class LineReassembler {
  final StringBuffer _buffer = StringBuffer();
  static const int _maxBuffer = 512; // 개행 없는 폭주 방지 가드.

  /// 바이트 조각 추가 → 완성된 라인들(개행 제외)을 순서대로 반환.
  Iterable<String> add(List<int> bytes) sync* {
    // 라틴/ASCII 프로토콜. 깨진 바이트는 대체문자로 흘려 파서가 UnknownEvent 처리.
    final chunk = utf8.decode(bytes, allowMalformed: true);
    for (final ch in chunk.split('')) {
      if (ch == '\n') {
        yield _flush();
      } else if (ch != '\r') {
        _buffer.write(ch);
        if (_buffer.length > _maxBuffer) {
          // 폭주 라인 강제 종결.
          yield _flush();
        }
      }
    }
  }

  String _flush() {
    final s = _buffer.toString();
    _buffer.clear();
    return s;
  }

  void reset() => _buffer.clear();
}
