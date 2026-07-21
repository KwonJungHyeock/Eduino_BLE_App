// Author: eduino
// AT 커맨드 — 공통 ChatView(mono) 사용. "보이는 통신" 교보재.
// 모듈별 안내 분기(지시서 3): HC-06=미연결(AT 모드) 응답 / HM-10(BLE)=연결 중 응답.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bt_providers.dart';
import '../../providers/module_providers.dart';
import '../../widgets/chat_view.dart';

class TerminalScreen extends ConsumerWidget {
  const TerminalScreen({super.key});

  static const List<String> _atHm10 = ['AT', 'AT+NAME?', 'AT+ROLE?', 'AT+RESET'];
  static const List<String> _atHc06 = ['AT', 'AT+VERSION', 'AT+NAME', 'AT+BAUD4'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(moduleProvider).valueOrNull ?? BtModule.ble;
    final connected = ref.watch(connectionProvider).isConnected;
    final isSpp = module == BtModule.spp; // HC-06

    // 모순 없는 안내(현재 모듈·연결 상태 기준).
    final String hint;
    if (isSpp) {
      hint = connected
          ? '연결 중에는 AT 명령이 아두이노로 전달됩니다. 모듈 설정은 페어링 전 AT 모드에서 하세요.'
          : 'HC-06은 미연결(AT 모드)에서 AT 명령에 응답합니다. 예: AT';
    } else {
      hint = connected
          ? 'HM-10은 연결 중 AT 명령에 응답합니다. 예: AT+NAME?'
          : '먼저 상단에서 HM-10에 연결하면 AT 명령에 응답합니다.';
    }

    return ChatView(
      mono: true,
      hint: hint,
      placeholder: 'RAW 명령 입력 (예: AT+NAME?)',
      presets: isSpp ? _atHc06 : _atHm10,
      showSystem: true,
      showTxRx: true,
      emptyIcon: Icons.terminal,
    );
  }
}
