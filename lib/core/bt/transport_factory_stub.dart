// Author: eduino
// 웹 전송 팩토리 — BT 패키지를 import 하지 않는다. 항상 스텁 전송을 반환(데모용).

import 'bt_transport.dart';
import 'stub_transport.dart';

BtTransport createTransport(BtModule module) => StubTransport();
