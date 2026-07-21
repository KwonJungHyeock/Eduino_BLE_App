// Author: eduino
// 네이티브 전송 팩토리 — 실제 BLE(HM-10)/SPP(HC-06). dart:io 환경에서만 컴파일된다.
// HC-06(SPP)은 Android 전용, 그 외는 BLE.

import 'package:flutter/foundation.dart';

import 'ble_transport.dart';
import 'bt_transport.dart';
import 'spp_transport.dart';

BtTransport createTransport(BtModule module) =>
    (module == BtModule.spp && defaultTargetPlatform == TargetPlatform.android)
        ? SppTransport()
        : BleTransport();
