// Author: eduino
// 시리얼 통신 채팅 — 공통 ChatView(sans) 사용. 편집 가능한 빠른 문장.
//   앱 입력  → BT → 아두이노 → "[App → Arduino]" PC 시리얼 모니터 출력
//   PC 입력  → 아두이노 → BT → 앱에 수신 표시

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/serial_presets_provider.dart';
import '../../widgets/chat_view.dart';

class SerialChatScreen extends ConsumerWidget {
  const SerialChatScreen({super.key});

  static const List<String> _fallback = [
    '안녕하세요',
    'hello',
    'LED ON',
    'LED OFF',
    '1',
    '0'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(serialPresetsProvider).valueOrNull ?? _fallback;
    return ChatView(
      mono: false,
      hint: '앱 ↔ 아두이노 ↔ PC 시리얼 모니터로 글자를 주고받아요. (9600 bps)',
      placeholder: '메시지 입력…',
      presets: presets,
      showTxRx: true,
      emptyIcon: Icons.forum_outlined,
      onAddPreset: (t) => ref.read(serialPresetsProvider.notifier).add(t),
      onRemovePreset: (t) => ref.read(serialPresetsProvider.notifier).remove(t),
    );
  }
}
