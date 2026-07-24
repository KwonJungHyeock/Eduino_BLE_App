// Author: eduino
// 통신·텔레메트리·터미널 전역 상태 (Riverpod). 화면은 이 provider 들로만 통신을 만난다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bt/bt_transport.dart';
import '../core/bt/transport_factory.dart';
import '../core/protocol/commands.dart';
import '../core/protocol/telemetry.dart';
import '../features/kit/kit_profile.dart';
import 'kit_providers.dart';
import 'module_providers.dart';

// connectionProvider 등의 공개 타입이 여기에 있으므로, 확장(isConnected/isBusy)까지
// 함께 노출해 이 파일만 import 해도 화면에서 바로 쓸 수 있게 한다.
export '../core/bt/bt_transport.dart'
    show BtConnectionState, BtConnectionStateX, BtDevice, BtModule;

// ---------------------------------------------------------------------------
// 전송 계층
// ---------------------------------------------------------------------------

/// 선택한 모듈에 맞는 전송 계층. HM-10→BLE, HC-06→Classic SPP(안드로이드).
/// 모듈을 바꾸면 provider 가 재생성되며 이전 전송은 dispose 된다(연결은 끊김).
final transportProvider = Provider<BtTransport>((ref) {
  final module = ref.watch(moduleProvider).valueOrNull ?? BtModule.ble;
  final BtTransport t = createTransport(module);
  ref.onDispose(t.dispose);
  return t;
});

/// 연결 상태 변화 스트림.
final connectionStreamProvider = StreamProvider<BtConnectionState>((ref) {
  return ref.watch(transportProvider).stateStream;
});

/// 동기 조회용 연결 상태(스트림 첫 방출 전에도 현재값 제공).
final connectionProvider = Provider<BtConnectionState>((ref) {
  final async = ref.watch(connectionStreamProvider);
  return async.valueOrNull ?? ref.watch(transportProvider).state;
});

/// 스캔 결과 — 화면이 구독하면 스캔 시작, 벗어나면 autoDispose 로 중지.
final scanResultsProvider =
    StreamProvider.autoDispose<List<BtDevice>>((ref) {
  return ref.watch(transportProvider).scan();
});

/// 수신 원시 조각 → \n 재조립 → 라인 스트림. telemetry/terminal 이 공유 구독.
/// 연결 직후 재조립 버퍼를 flush(0-5) — 이전 세션/모듈의 잔여 쓰레기값 제거.
final incomingLineProvider = StreamProvider<String>((ref) {
  final transport = ref.watch(transportProvider);
  final reassembler = LineReassembler();
  ref.listen<BtConnectionState>(connectionProvider, (prev, next) {
    if (next == BtConnectionState.connected) reassembler.reset();
  });
  return transport.incoming.expand(reassembler.add);
});

/// 수신 원시 바이트 스트림 — 팩토리 단일문자(y/n/r/g/b, 개행 없음) 처리용(QA 0-3/0-5).
final rawIncomingProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(transportProvider).incoming;
});

// ---------------------------------------------------------------------------
// 텔레메트리 상태 (§4.3)
// ---------------------------------------------------------------------------

class TelemetryState {
  const TelemetryState({
    this.distanceCm,
    this.line,
    this.mode = DriveMode.manual,
    this.batteryPercent,
    this.lastAck,
    this.sensors = const {},
    this.factoryRunning,
    this.sortCounts = const {'r': 0, 'g': 0, 'b': 0},
    this.lastSort,
  });

  final int? distanceCm;
  final ({int l, int c, int r})? line;
  final DriveMode mode;
  final int? batteryPercent;
  final String? lastAck;

  /// 범용 센서값 맵(TMP/HUM/SOL/LUX/OBJ 등) — 교구 센서 패널에서 사용.
  final Map<String, double> sensors;

  // ── 스마트 팩토리 실데이터(QA 0-3) ──
  final bool? factoryRunning; // y/n
  final Map<String, int> sortCounts; // 색별 분류 누적 {r,g,b}
  final String? lastSort; // 마지막 분류 색('r'/'g'/'b') — 라인 애니메이션 트리거

  int get sortTotal =>
      (sortCounts['r'] ?? 0) + (sortCounts['g'] ?? 0) + (sortCounts['b'] ?? 0);

  TelemetryState _apply(TelemetryEvent e) {
    switch (e) {
      case DistanceEvent(:final cm):
        return _copy(distanceCm: cm);
      case LineSensorEvent(:final left, :final center, :final right):
        return _copy(line: (l: left, c: center, r: right));
      case ModeEvent(:final mode):
        return _copy(mode: mode);
      case BatteryEvent(:final percent):
        return _copy(batteryPercent: percent);
      case AckEvent(:final cmd):
        return _copy(lastAck: cmd);
      case SensorEvent(:final key, :final value):
        return _copy(sensors: {...sensors, key: value});
      case LogEvent():
      case UnknownEvent():
        return this;
    }
  }

  TelemetryState _copy({
    int? distanceCm,
    ({int l, int c, int r})? line,
    DriveMode? mode,
    int? batteryPercent,
    String? lastAck,
    Map<String, double>? sensors,
    bool? factoryRunning,
    Map<String, int>? sortCounts,
    String? lastSort,
  }) =>
      TelemetryState(
        distanceCm: distanceCm ?? this.distanceCm,
        line: line ?? this.line,
        mode: mode ?? this.mode,
        batteryPercent: batteryPercent ?? this.batteryPercent,
        lastAck: lastAck ?? this.lastAck,
        sensors: sensors ?? this.sensors,
        factoryRunning: factoryRunning ?? this.factoryRunning,
        sortCounts: sortCounts ?? this.sortCounts,
        lastSort: lastSort ?? this.lastSort,
      );

  /// 팩토리 단일문자 이벤트 반영(y/n 상태, r/g/b 색별 카운트).
  TelemetryState _applyFactory(FactoryChar e) {
    switch (e) {
      case FactoryChar.running:
        return _copy(factoryRunning: true);
      case FactoryChar.stopped:
        return _copy(factoryRunning: false);
      case FactoryChar.sortRed:
      case FactoryChar.sortGreen:
      case FactoryChar.sortBlue:
        final k = e == FactoryChar.sortRed
            ? 'r'
            : e == FactoryChar.sortGreen
                ? 'g'
                : 'b';
        final next = {...sortCounts, k: (sortCounts[k] ?? 0) + 1};
        return _copy(sortCounts: next, lastSort: k);
      case FactoryChar.none:
        return this;
    }
  }
}

/// 수신 라인을 디코딩해 최신 텔레메트리 상태로 유지. 연결 끊기면 초기화.
class TelemetryNotifier extends Notifier<TelemetryState> {
  @override
  TelemetryState build() {
    ref.listen<BtConnectionState>(connectionProvider, (prev, next) {
      if (next == BtConnectionState.disconnected) {
        state = const TelemetryState();
      }
    });
    ref.listen<AsyncValue<String>>(incomingLineProvider, (prev, next) {
      final line = next.valueOrNull;
      if (line == null || line.isEmpty) return;
      final event = TelemetryDecoder.decode(line);
      // 접두어 없는 라인은 교구(스마트킷) 모니터링 텍스트로 해석 시도(팜/홈).
      if (event is UnknownEvent) {
        final kit = ref.read(kitProfileProvider).valueOrNull;
        if (kit != null && !kit.isRc) {
          final sensors = parseMonitorText(line);
          if (sensors.isNotEmpty) {
            for (final s in sensors) {
              state = state._apply(s);
            }
            return;
          }
        }
      }
      state = state._apply(event);
    });
    // 팩토리(스마트 팩토리) 단일문자 회신 — 라인 없는 y/n/r/g/b 를 바이트 단위로 처리.
    ref.listen<AsyncValue<List<int>>>(rawIncomingProvider, (prev, next) {
      final bytes = next.valueOrNull;
      if (bytes == null) return;
      final kit = ref.read(kitProfileProvider).valueOrNull;
      if (kit?.type != KitType.smartFactory) return;
      for (final b in bytes) {
        final e = decodeFactoryChar(b);
        if (e != FactoryChar.none) state = state._applyFactory(e);
      }
    });
    return const TelemetryState();
  }
}

final telemetryProvider =
    NotifierProvider<TelemetryNotifier, TelemetryState>(TelemetryNotifier.new);

// ---------------------------------------------------------------------------
// 터미널 로그 (§5.9) — "보이는 통신"
// ---------------------------------------------------------------------------

enum LogDir { out, incoming, system }

class TerminalEntry {
  const TerminalEntry(this.dir, this.text, this.atMillis);
  final LogDir dir;
  final String text;
  final int atMillis;
}

class TerminalNotifier extends Notifier<List<TerminalEntry>> {
  static const int _cap = 500;

  @override
  List<TerminalEntry> build() {
    ref.listen<AsyncValue<String>>(incomingLineProvider, (prev, next) {
      final line = next.valueOrNull;
      if (line == null || line.isEmpty) return;
      _append(LogDir.incoming, line);
    });
    // 연결 상태는 상단 앵커바(StatusBar)가 상시 표시하므로 채팅 로그에는
    // 연결 상태 시스템 칩을 남기지 않는다(3차 항목3 · 이중 표시 제거).
    return const [];
  }

  void _append(LogDir dir, String text) {
    final entry = TerminalEntry(dir, text, DateTime.now().millisecondsSinceEpoch);
    final next = [...state, entry];
    state = next.length > _cap ? next.sublist(next.length - _cap) : next;
  }

  /// CarController 가 송신 프레임을 여기로 기록(회색=송신).
  void logOutgoing(String frame) => _append(LogDir.out, frame);

  void clear() => state = const [];
}

final terminalProvider =
    NotifierProvider<TerminalNotifier, List<TerminalEntry>>(
        TerminalNotifier.new);
