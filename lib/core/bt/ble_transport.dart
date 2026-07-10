// Author: eduino
// HM-10 (BLE) 전송 구현 (§2.2). flutter_blue_plus 를 캡슐화하는 유일한 지점.
// 표준 GATT: Service FFE0 / Characteristic FFE1 (Write + Notify).

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'bt_transport.dart';

/// HM-10 표준 UUID (§2.2).
final Guid _hm10Service = Guid('0000FFE0-0000-1000-8000-00805F9B34FB');
final Guid _hm10Char = Guid('0000FFE1-0000-1000-8000-00805F9B34FB');

/// BLE 1회 write 페이로드 상한 (§2.2). MTU 23 → ATT 헤더 3바이트 제외.
const int _bleWriteChunk = 20;

class BleTransport implements BtTransport {
  BleTransport();

  final StreamController<BtConnectionState> _stateCtrl =
      StreamController<BtConnectionState>.broadcast();
  final StreamController<List<int>> _incomingCtrl =
      StreamController<List<int>>.broadcast();

  BtConnectionState _state = BtConnectionState.disconnected;
  BtDevice? _connectedDevice;

  BluetoothDevice? _fbpDevice;
  BluetoothCharacteristic? _txrx;
  bool _writeWithoutResponse = false;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  @override
  BtModule get module => BtModule.ble;

  @override
  BtConnectionState get state => _state;

  @override
  Stream<BtConnectionState> get stateStream => _stateCtrl.stream;

  @override
  BtDevice? get connectedDevice => _connectedDevice;

  @override
  Stream<List<int>> get incoming => _incomingCtrl.stream;

  void _setState(BtConnectionState s) {
    if (_state == s) return;
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  // ---- 스캔 ----------------------------------------------------------------

  @override
  Stream<List<BtDevice>> scan({Duration timeout = const Duration(seconds: 12)}) {
    // 발견 기기 누적 후 스냅샷 방출. FFE0 광고 기기는 isKnownModule=true.
    final controller = StreamController<List<BtDevice>>();
    final Map<String, BtDevice> found = {};

    controller.onListen = () async {
      try {
        _setState(BtConnectionState.scanning);
        _scanSub?.cancel();
        _scanSub = FlutterBluePlus.scanResults.listen((results) {
          var changed = false;
          for (final r in results) {
            final name = r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : r.device.platformName;
            final knows = r.advertisementData.serviceUuids
                .any((g) => g == _hm10Service);
            final dev = BtDevice(
              id: r.device.remoteId.str,
              name: name,
              rssi: r.rssi,
              isKnownModule: knows,
            );
            found[dev.id] = dev;
            changed = true;
          }
          if (changed && !controller.isClosed) {
            final list = found.values.toList()
              ..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
            controller.add(list);
          }
        });

        await FlutterBluePlus.startScan(
          timeout: timeout,
          androidUsesFineLocation: false,
        );
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      } finally {
        if (_state == BtConnectionState.scanning) {
          _setState(BtConnectionState.disconnected);
        }
      }
    };

    controller.onCancel = () async {
      await stopScan();
    };

    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    } catch (_) {/* ignore */}
    if (_state == BtConnectionState.scanning) {
      _setState(_connectedDevice != null
          ? BtConnectionState.connected
          : BtConnectionState.disconnected);
    }
  }

  // ---- 연결 ----------------------------------------------------------------

  @override
  Future<void> connect(BtDevice device) async {
    await stopScan();
    _setState(BtConnectionState.connecting);

    final fbp = BluetoothDevice.fromId(device.id);
    _fbpDevice = fbp;

    // 연결 상태 추적 — 끊김 시 즉시 상태 반영(안전 정지는 상위 CarController 담당).
    await _connSub?.cancel();
    _connSub = fbp.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });

    try {
      await fbp.connect(timeout: const Duration(seconds: 15));
      await _discover(fbp);
      _connectedDevice = device;
      _setState(BtConnectionState.connected);
    } catch (e) {
      await _cleanupConnection();
      _setState(BtConnectionState.disconnected);
      rethrow;
    }
  }

  Future<void> _discover(BluetoothDevice fbp) async {
    final services = await fbp.discoverServices();
    BluetoothCharacteristic? target;
    for (final s in services) {
      if (s.uuid != _hm10Service) continue;
      for (final c in s.characteristics) {
        if (c.uuid == _hm10Char) {
          target = c;
          break;
        }
      }
    }
    // 일부 클론 모듈은 UUID 가 미세하게 다를 수 있어 write+notify 특성으로 폴백.
    target ??= _fallbackCharacteristic(services);
    if (target == null) {
      throw StateError('HM-10 특성(FFE1)을 찾지 못했습니다. 모듈을 확인하세요.');
    }

    _txrx = target;
    _writeWithoutResponse = target.properties.writeWithoutResponse;

    if (target.properties.notify || target.properties.indicate) {
      await target.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = target.onValueReceived.listen((bytes) {
        if (bytes.isNotEmpty && !_incomingCtrl.isClosed) {
          _incomingCtrl.add(bytes);
        }
      });
    }
  }

  BluetoothCharacteristic? _fallbackCharacteristic(
      List<BluetoothService> services) {
    for (final s in services) {
      for (final c in s.characteristics) {
        final p = c.properties;
        final canWrite = p.write || p.writeWithoutResponse;
        final canRead = p.notify || p.indicate;
        if (canWrite && canRead) return c;
      }
    }
    return null;
  }

  void _onDisconnected() {
    _connectedDevice = null;
    _txrx = null;
    _setState(BtConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _setState(BtConnectionState.disconnecting);
    await _cleanupConnection();
    _setState(BtConnectionState.disconnected);
  }

  Future<void> _cleanupConnection() async {
    await _notifySub?.cancel();
    _notifySub = null;
    try {
      await _fbpDevice?.disconnect();
    } catch (_) {/* ignore */}
    await _connSub?.cancel();
    _connSub = null;
    _txrx = null;
    _connectedDevice = null;
    _fbpDevice = null;
  }

  // ---- 송신 ----------------------------------------------------------------

  @override
  Future<void> send(List<int> bytes) async {
    final ch = _txrx;
    if (ch == null || _state != BtConnectionState.connected) {
      // 연결 가드: 미연결 상태 송신은 조용히 무시(상위 CarController 도 가드).
      return;
    }
    // 20바이트 분할 (§2.2 · §9.2).
    for (var i = 0; i < bytes.length; i += _bleWriteChunk) {
      final end =
          (i + _bleWriteChunk < bytes.length) ? i + _bleWriteChunk : bytes.length;
      final chunk = bytes.sublist(i, end);
      await ch.write(chunk, withoutResponse: _writeWithoutResponse);
    }
  }

  @override
  Future<void> dispose() async {
    await stopScan();
    await _cleanupConnection();
    await _stateCtrl.close();
    await _incomingCtrl.close();
  }
}
