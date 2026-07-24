// Author: eduino
// AT 커맨드 — 공통 ChatView(mono) 사용. "보이는 통신" 교보재.
// 모듈별 안내 분기(지시서 3): HC-06=미연결(AT 모드) 응답 / HM-10(BLE)=연결 중 응답.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../providers/module_providers.dart';
import '../../widgets/chat_view.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  static const List<String> _atHm10 = ['AT', 'AT+NAME?', 'AT+ROLE?', 'AT+RESET'];
  static const List<String> _atHc06 = ['AT', 'AT+VERSION', 'AT+NAME', 'AT+BAUD4'];

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  @override
  void initState() {
    super.initState();
    // 재시작 시 로그 초기화 + RC 주행 하트비트(PNG:) 억제 → AT 교보재 로그를 깨끗하게 시작.
    // 위젯 트리 빌드 중 provider 수정 금지 → 첫 프레임 이후로 지연.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(terminalProvider.notifier).clear();
      ref.read(carControllerProvider).pauseHeartbeat();
    });
  }

  @override
  void dispose() {
    ref.read(carControllerProvider).resumeHeartbeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      placeholder: '명령 직접 입력 (예: AT+NAME?)',
      presets: isSpp ? TerminalScreen._atHc06 : TerminalScreen._atHm10,
      showSystem: true,
      showTxRx: true,
      emptyIcon: Icons.terminal,
    );
  }
}
