// Author: eduino
// HC-06 (Classic Bluetooth SPP) 전송 구현 — Android 전용.
// flutter_bluetooth_serial 을 캡슐화하는 유일한 지점. 상위는 BtTransport 로만 만난다.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'bt_transport.dart';

class SppTransport implements BtTransport {
  SppTransport();

  final StreamController<BtConnectionState> _stateCtrl =
      StreamController<BtConnectionState>.broadcast();
  final StreamController<List<int>> _incomingCtrl =
      StreamController<List<int>>.broadcast();

  BtConnectionState _state = BtConnectionState.disconnected;
  BtDevice? _connectedDevice;

  BluetoothConnection? _conn;
  StreamSubscription<Uint8List>? _inputSub;
  StreamSubscription<BluetoothDiscoveryResult>? _discSub;

  @override
  BtModule get module => BtModule.spp;

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

  // ---- 스캔: 페어링된 기기 + 검색 결과 ---------------------------------------

  @override
  Stream<List<BtDevice>> scan({Duration timeout = const Duration(seconds: 12)}) {
    final controller = StreamController<List<BtDevice>>();
    final Map<String, BtDevice> found = {};

    controller.onListen = () async {
      try {
        _setState(BtConnectionState.scanning);
        // 이미 페어링(등록)된 기기부터 표시 — HC-06 은 보통 설정에서 미리 페어링(PIN 1234).
        final bonded =
            await FlutterBluetoothSerial.instance.getBondedDevices();
        for (final d in bonded) {
          found[d.address] = BtDevice(
            id: d.address,
            name: d.name ?? '',
            module: BtModule.spp,
            isKnownModule: true,
          );
        }
        if (!controller.isClosed) controller.add(found.values.toList());

        // 주변 검색도 병행.
        _discSub = FlutterBluetoothSerial.instance.startDiscovery().listen(
          (r) {
            found[r.device.address] = BtDevice(
              id: r.device.address,
              name: r.device.name ?? '',
              rssi: r.rssi,
              module: BtModule.spp,
              isKnownModule: r.device.isBonded,
            );
            if (!controller.isClosed) controller.add(found.values.toList());
          },
          onDone: () {
            if (_state == BtConnectionState.scanning) {
              _setState(BtConnectionState.disconnected);
            }
          },
        );
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    };

    controller.onCancel = () async {
      await stopScan();
    };

    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    await _discSub?.cancel();
    _discSub = null;
    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
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
    try {
      final c = await BluetoothConnection.toAddress(device.id);
      _conn = c;
      _connectedDevice = device;
      _setState(BtConnectionState.connected);
      _inputSub = c.input?.listen(
        (data) {
          if (data.isNotEmpty && !_incomingCtrl.isClosed) {
            _incomingCtrl.add(data);
          }
        },
        onDone: _onDisconnected,
      );
    } catch (e) {
      _connectedDevice = null;
      _conn = null;
      _setState(BtConnectionState.disconnected);
      rethrow;
    }
  }

  void _onDisconnected() {
    _connectedDevice = null;
    _conn = null;
    _setState(BtConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _setState(BtConnectionState.disconnecting);
    await _inputSub?.cancel();
    _inputSub = null;
    try {
      await _conn?.finish();
    } catch (_) {/* ignore */}
    _conn = null;
    _connectedDevice = null;
    _setState(BtConnectionState.disconnected);
  }

  // ---- 송신 ----------------------------------------------------------------

  @override
  Future<void> send(List<int> bytes) async {
    final c = _conn;
    if (c == null || _state != BtConnectionState.connected) return;
    c.output.add(Uint8List.fromList(bytes));
    try {
      await c.output.allSent;
    } catch (_) {/* ignore */}
  }

  @override
  Future<void> dispose() async {
    await stopScan();
    await _inputSub?.cancel();
    try {
      await _conn?.finish();
    } catch (_) {/* ignore */}
    await _stateCtrl.close();
    await _incomingCtrl.close();
  }
}
