// Author: eduino
// iOS 배너 판정용 — 실제 BLE 어댑터 상태(켜짐/꺼짐·미승인).
// 아키텍처 규칙상 통신 패키지(flutter_blue_plus)는 providers/·core/bt/ 만 알 수 있으므로,
// 화면은 이 provider 로만 어댑터 상태를 만난다.

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 블루투스 어댑터가 켜져 있고 앱이 사용 가능한 상태(on)인지.
/// 스트림 첫 방출 전에도 adapterStateNow 로 현재값을 먼저 준다(초기 오표시 방지).
final bluetoothOnProvider = StreamProvider<bool>((ref) async* {
  yield FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
  yield* FlutterBluePlus.adapterState.map((s) => s == BluetoothAdapterState.on);
});
