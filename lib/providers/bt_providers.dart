// Author: eduino
// 통신·텔레메트리·터미널 전역 상태 (Riverpod). 화면은 이 provider 들로만 통신을 만난다.

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bt/ble_transport.dart';
import '../core/bt/bt_transport.dart';
import '../core/bt/spp_transport.dart';
import '../core/protocol/commands.dart';
import '../core/protocol/telemetry.dart';
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
  final BtTransport t = (module == BtModule.spp && Platform.isAndroid)
      ? SppTransport()
      : BleTransport();
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
final incomingLineProvider = StreamProvider<String>((ref) {
  final transport = ref.watch(transportProvider);
  final reassembler = LineReassembler();
  return transport.incoming.expand(reassembler.add);
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
  });

  final int? distanceCm;
  final ({int l, int c, int r})? line;
  final DriveMode mode;
  final int? batteryPercent;
  final String? lastAck;

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
  }) =>
      TelemetryState(
        distanceCm: distanceCm ?? this.distanceCm,
        line: line ?? this.line,
        mode: mode ?? this.mode,
        batteryPercent: batteryPercent ?? this.batteryPercent,
        lastAck: lastAck ?? this.lastAck,
      );
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
      state = state._apply(TelemetryDecoder.decode(line));
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
    ref.listen<BtConnectionState>(connectionProvider, (prev, next) {
      if (prev == next) return;
      _append(LogDir.system, '연결 상태: ${next.name}');
    });
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
