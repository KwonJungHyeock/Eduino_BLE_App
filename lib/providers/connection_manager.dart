// Author: eduino
// 연결 관리자 — 예상치 못한 끊김 시 지난 기기로 자동 재연결(지수 백오프).
// 수업 중 신호가 잠깐 끊겨도 다시 붙는다. 사용자가 직접 끊은 경우엔 재연결하지 않는다.
// 안전: 재연결은 마지막으로 성공한 기기에만 시도(임의 기기에 붙지 않음).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bt/bt_transport.dart';
import 'bt_providers.dart';
import 'last_device_providers.dart';

/// 자동 재연결 진행 여부(UI 표시용).
final reconnectingProvider = StateProvider<bool>((ref) => false);

class ConnectionManager {
  ConnectionManager(this._ref);
  final Ref _ref;

  static const List<int> _backoffSec = [2, 4, 8, 16, 16];
  static const int _maxAttempts = 5;

  bool _userInitiated = false; // 사용자가 의도적으로 끊었는가
  int _attempt = 0;
  Timer? _retry;

  void onStateChanged(BtConnectionState prev, BtConnectionState next) {
    if (next == BtConnectionState.connected) {
      _reset();
      return;
    }
    if (prev == BtConnectionState.connected &&
        next == BtConnectionState.disconnected) {
      if (_userInitiated) {
        _userInitiated = false;
        return;
      }
      _scheduleReconnect();
    }
  }

  /// 앱이 다시 활성화될 때 — 끊겨 있으면 재연결 시도.
  void onResume() {
    final st = _ref.read(transportProvider).state;
    if (st == BtConnectionState.disconnected && !_userInitiated) {
      _attempt = 0;
      _scheduleReconnect();
    }
  }

  /// 사용자가 직접 끊기 — 이후 자동 재연결하지 않는다.
  Future<void> userDisconnect() async {
    _userInitiated = true;
    _cancelRetry();
    await _ref.read(transportProvider).disconnect();
  }

  void _scheduleReconnect() {
    final last = _ref.read(lastDeviceProvider).valueOrNull;
    if (last == null) {
      _stopReconnecting();
      return;
    }
    if (_attempt >= _maxAttempts) {
      _stopReconnecting(); // 포기 — 사용자가 직접 재시도
      return;
    }
    final delay = Duration(seconds: _backoffSec[_attempt.clamp(0, 4)]);
    _attempt++;
    _setReconnecting(true);
    _cancelRetry();
    _retry = Timer(delay, () async {
      final st = _ref.read(transportProvider).state;
      if (st == BtConnectionState.connected ||
          st == BtConnectionState.connecting) {
        return;
      }
      try {
        await _ref.read(transportProvider).connect(last.toDevice());
        // 성공 시 onStateChanged(connected)에서 _reset.
      } catch (_) {
        _scheduleReconnect(); // 실패 → 다음 백오프
      }
    });
  }

  void _reset() {
    _userInitiated = false;
    _attempt = 0;
    _cancelRetry();
    _stopReconnecting();
  }

  void _stopReconnecting() => _setReconnecting(false);

  void _setReconnecting(bool v) {
    final n = _ref.read(reconnectingProvider.notifier);
    if (n.state != v) n.state = v;
  }

  void _cancelRetry() {
    _retry?.cancel();
    _retry = null;
  }

  void dispose() => _cancelRetry();
}

/// 연결 상태를 구독해 자동 재연결을 관리. main 에서 즉시 인스턴스화한다.
final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  final m = ConnectionManager(ref);
  ref.listen<BtConnectionState>(
    connectionProvider,
    (prev, next) =>
        m.onStateChanged(prev ?? BtConnectionState.disconnected, next),
  );
  ref.onDispose(m.dispose);
  return m;
});
