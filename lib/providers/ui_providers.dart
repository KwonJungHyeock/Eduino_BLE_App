// Author: eduino
// 화면 간 공유되는 조작 UI 상태(전송값이 아니라 슬라이더 위치 등). 실제 전송은 CarController.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 속도 상한(%) — 조이스틱·방향버튼 공유 (§5.2·§5.3). 0..100.
final speedCapProvider = StateProvider<int>((ref) => 60);
