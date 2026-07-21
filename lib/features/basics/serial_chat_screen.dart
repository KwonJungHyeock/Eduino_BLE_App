// Author: eduino
// 시리얼 통신 채팅 — 앱 ↔ (블루투스) ↔ 아두이노 ↔ PC 시리얼 모니터.
// 문자열을 채팅처럼 주고받는 실습. 아두이노는 SoftwareSerial 로 BT↔Serial 을 중계.
//   앱 입력  → BT → 아두이노 → "[App → Arduino]" PC 시리얼 모니터 출력
//   PC 입력  → 아두이노 → BT → 앱에 수신 표시

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';

class SerialChatScreen extends ConsumerStatefulWidget {
  const SerialChatScreen({super.key});

  @override
  ConsumerState<SerialChatScreen> createState() => _SerialChatScreenState();
}

class _SerialChatScreenState extends ConsumerState<SerialChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static const List<String> _presets = ['안녕하세요', 'hello', 'LED ON', 'LED OFF', '1', '0'];

  void _sendText(String t) {
    final text = t.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(carControllerProvider).sendPlain(text);
    _scrollToEnd();
  }

  void _send() {
    _sendText(_input.text);
    _input.clear();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;
    // 시스템 로그 제외한 실제 채팅(송/수신)만 표시.
    final chat = ref
        .watch(terminalProvider)
        .where((e) => e.dir != LogDir.system)
        .toList();
    ref.listen(terminalProvider, (_, __) => _scrollToEnd());

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.signalTint,
          padding:
              const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '앱↔아두이노↔PC 시리얼 모니터로 글자를 주고받습니다. (9600 bps)',
                  style: AppType.mono(
                      size: 11, color: AppColors.textMuted, height: 1.4),
                ),
              ),
              if (chat.isNotEmpty)
                GestureDetector(
                  onTap: () => ref.read(terminalProvider.notifier).clear(),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.textMuted),
                      Text('지우기',
                          style: AppType.mono(
                              size: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFEDF1F6), // 채팅 배경(말풍선이 뜨게)
            child: chat.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.forum_outlined,
                            size: 40, color: AppColors.chevron),
                        const SizedBox(height: 12),
                        Text(
                          connected ? '메시지를 입력해 보세요.' : '연결 후 채팅할 수 있어요.',
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.listDesc),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    itemCount: chat.length,
                    itemBuilder: (context, i) => _Bubble(entry: chat[i]),
                  ),
          ),
        ),
        // 자주 쓰는 문장 프리셋
        if (connected)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              itemCount: _presets.length,
              separatorBuilder: (_, __) => Gap.w8,
              itemBuilder: (context, i) => Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => _sendText(_presets[i]),
                  child: Text(_presets[i], style: AppType.mono(size: 12)),
                ),
              ),
            ),
          ),
        _InputBar(controller: _input, enabled: connected, onSend: _send),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.entry});
  final TerminalEntry entry;

  @override
  Widget build(BuildContext context) {
    final mine = entry.dir == LogDir.out;
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? AppColors.signal : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
          border: mine ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          entry.text,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.35,
            color: mine ? Colors.white : AppColors.listTitle,
          ),
        ),
      ),
    );
    final time = Text(
      _hhmm(entry.atMillis),
      style: const TextStyle(fontSize: 10, color: AppColors.listDesc),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine
            ? [time, Gap.w8, bubble]
            : [bubble, Gap.w8, time],
      ),
    );
  }

  static String _hhmm(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                style: const TextStyle(fontSize: 14.5),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: enabled ? '메시지 입력…' : '연결 후 입력 가능',
                  hintStyle: const TextStyle(
                      fontSize: 14, color: AppColors.listDesc),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.signal),
                  ),
                ),
              ),
            ),
            Gap.w8,
            FilledButton(
              onPressed: enabled ? onSend : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(54, 48),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
