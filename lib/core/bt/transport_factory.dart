// Author: eduino
// 전송 계층 팩토리 — 조건부 import 로 플랫폼별 구현을 고른다.
//   네이티브(dart:io 존재): 실제 BLE(HM-10)/SPP(HC-06) 구현.
//   웹(dart:io 없음): 스텁 전송 → BT 패키지를 아예 컴파일하지 않아 웹 빌드가 가능.

import 'bt_transport.dart';
import 'transport_factory_stub.dart'
    if (dart.library.io) 'transport_factory_io.dart' as impl;

/// 선택한 모듈에 맞는 전송 계층을 생성.
BtTransport createTransport(BtModule module) => impl.createTransport(module);
