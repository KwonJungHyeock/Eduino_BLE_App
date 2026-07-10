// Author: eduino
// 통신 추상화 (§2.3). 상위 화면은 이 인터페이스만 알고, 실제 모듈 구현(BLE/SPP)을 주입받는다.
// 화면/위젯은 flutter_blue_plus / flutter_bluetooth_serial 를 직접 import 하지 않는다.

import 'dart:async';

/// 연결 상태.
enum BtConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

extension BtConnectionStateX on BtConnectionState {
  bool get isConnected => this == BtConnectionState.connected;
  bool get isBusy =>
      this == BtConnectionState.connecting ||
      this == BtConnectionState.disconnecting;
}

/// 통신 모듈 종류.
enum BtModule {
  /// HM-10 (BLE) — 주력·크로스플랫폼 (§2.2)
  ble,

  /// HC-06 (Classic SPP) — Android 전용 (§2.1). 현재 스코프 미구현, 슬롯만.
  spp,
}

/// 스캔으로 발견한 기기(전송 계층 중립 모델).
class BtDevice {
  const BtDevice({
    required this.id,
    required this.name,
    this.rssi,
    this.module = BtModule.ble,
    this.isKnownModule = false,
  });

  /// 플랫폼 식별자 (BLE remoteId / SPP MAC).
  final String id;
  final String name;
  final int? rssi;
  final BtModule module;

  /// HM-10 표준 서비스(FFE0) 광고 등, 우리 앱이 아는 모듈로 보이면 true.
  final bool isKnownModule;

  String get displayName => name.isNotEmpty ? name : id;

  @override
  bool operator ==(Object other) =>
      other is BtDevice && other.id == id && other.module == module;

  @override
  int get hashCode => Object.hash(id, module);
}

/// 상위 화면이 의존하는 유일한 통신 계약.
abstract class BtTransport {
  BtModule get module;

  /// 현재 연결 상태(동기 조회).
  BtConnectionState get state;

  /// 연결 상태 변화 스트림.
  Stream<BtConnectionState> get stateStream;

  /// 연결된 기기(없으면 null).
  BtDevice? get connectedDevice;

  /// 스캔 시작 — 발견되는 기기를 스트림으로 방출. 구독 취소 시 스캔 중지.
  Stream<List<BtDevice>> scan({Duration timeout});

  /// 스캔 중지.
  Future<void> stopScan();

  Future<void> connect(BtDevice device);
  Future<void> disconnect();

  /// 바이트 전송. 20바이트 초과 프레임은 구현이 분할한다(§2.2).
  Future<void> send(List<int> bytes);

  /// 수신 원시 바이트(조각 가능). 브로드캐스트 스트림 — 여러 구독 허용.
  Stream<List<int>> get incoming;

  /// 리소스 정리.
  Future<void> dispose();
}
