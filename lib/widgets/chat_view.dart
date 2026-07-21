// Author: eduino
// 공통 채팅 뷰(지시서 0.5) — 시리얼 채팅 = AT 커맨드가 같은 컴포넌트.
// 다른 점: payloadFont(sans/mono), hint, placeholder, presets, TX/RX 라벨, 시스템 로그 표시.
//   말풍선: 송신=오른쪽 파랑 / 수신=왼쪽 흰 / 시스템=가운데 옅은 칩.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../providers/bt_providers.dart';
import '../providers/car_controller.dart';
import 'hint_banner.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({
    super.key,
    required this.mono,
    required this.hint,
    required this.placeholder,
    required this.presets,
    this.showSystem = false,
    this.showTxRx = true,
    this.emptyIcon = Icons.forum_outlined,
    this.onAddPreset,
    this.onRemovePreset,
  });

  final bool mono; // payload 폰트: true=mono(데이터) / false=sans(대화)
  final String hint;
  final String placeholder;
  final List<String> presets;
  final bool showSystem; // 시스템 로그를 가운데 칩으로 표시(AT)
  final bool showTxRx; // 말풍선에 TX/RX 미세 라벨
  final IconData emptyIcon;
  final void Function(String text)? onAddPreset; // 있으면 "+" 칩 표시(편집)
  final void Function(String text)? onRemovePreset; // 있으면 롱프레스 삭제

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

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

  Future<void> _addPresetDialog() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('빠른 문장 추가'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 안녕'),
          onSubmitted: (v) => Navigator.pop(d, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text),
              child: const Text('추가')),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      widget.onAddPreset?.call(text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;
    final entries = ref
        .watch(terminalProvider)
        .where((e) => widget.showSystem || e.dir != LogDir.system)
        .toList();
    ref.listen(terminalProvider, (_, __) => _scrollToEnd());

    return Column(
      children: [
        HintBanner(widget.hint),
        Expanded(
          child: Container(
            color: const Color(0xFFEDF1F6),
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.emptyIcon,
                            size: 40, color: AppColors.chevron),
                        const SizedBox(height: 12),
                        Text(
                          connected ? '메시지를 입력해 보세요.' : '연결 후 사용할 수 있어요.',
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.listDesc),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _Bubble(
                        entry: entries[i],
                        mono: widget.mono,
                        showTxRx: widget.showTxRx),
                  ),
          ),
        ),
        // 빠른 문장 칩(+ 편집) · 우측 지우기
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 12),
                  children: [
                    for (final p in widget.presets) ...[
                      _PresetChip(
                        label: p,
                        mono: widget.mono,
                        onTap: () => _sendText(p),
                        onLongPress: widget.onRemovePreset == null
                            ? null
                            : () => widget.onRemovePreset!.call(p),
                      ),
                      Gap.w8,
                    ],
                    if (widget.onAddPreset != null)
                      Center(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _addPresetDialog,
                          child: const Icon(Icons.add,
                              size: 16, color: AppColors.listDesc),
                        ),
                      ),
                  ],
                ),
              ),
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: '기록 지우기',
                  onPressed: () =>
                      ref.read(terminalProvider.notifier).clear(),
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.listDesc),
                ),
            ],
          ),
        ),
        _InputBar(
          controller: _input,
          mono: widget.mono,
          placeholder: widget.placeholder,
          onSend: _send,
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.entry, required this.mono, required this.showTxRx});
  final TerminalEntry entry;
  final bool mono;
  final bool showTxRx;

  @override
  Widget build(BuildContext context) {
    if (entry.dir == LogDir.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(entry.text,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.listDesc)),
          ),
        ),
      );
    }
    final mine = entry.dir == LogDir.out;
    final payloadStyle = mono
        ? AppType.mono(
            size: 13.5,
            height: 1.3,
            color: mine ? Colors.white : AppColors.listTitle)
        : TextStyle(
            fontSize: 14.5,
            height: 1.35,
            color: mine ? Colors.white : AppColors.listTitle);
    final bubble = ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
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
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showTxRx) ...[
              Text(
                mine ? 'TX · 보냄' : 'RX · 받음',
                style: AppType.mono(
                  size: 8.5,
                  letterSpacing: 0.5,
                  weight: FontWeight.w700,
                  color: mine
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.listDesc,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(entry.text, style: payloadStyle),
          ],
        ),
      ),
    );
    final time = Text(_hhmm(entry.atMillis),
        style: const TextStyle(fontSize: 10, color: AppColors.listDesc));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine ? [time, Gap.w8, bubble] : [bubble, Gap.w8, time],
      ),
    );
  }

  static String _hhmm(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.mono,
    required this.onTap,
    this.onLongPress,
  });
  final String label;
  final bool mono;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onLongPress: onLongPress == null
            ? null
            : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('빠른 문장 삭제'),
                    content: Text('"$label" 를 삭제할까요?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: const Text('취소')),
                      FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: const Text('삭제')),
                    ],
                  ),
                );
                if (ok == true) onLongPress!.call();
              },
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            side: const BorderSide(color: AppColors.cardBorder),
            shape: const StadiumBorder(),
          ),
          onPressed: onTap,
          child: Text(label,
              style: mono
                  ? AppType.mono(size: 12, color: AppColors.listTitle)
                  : const TextStyle(fontSize: 12.5, color: AppColors.listTitle)),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.mono,
    required this.placeholder,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool mono;
  final String placeholder;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: mono
                    ? AppType.mono(size: 14)
                    : const TextStyle(fontSize: 14.5),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: placeholder,
                  hintStyle: mono
                      ? AppType.mono(size: 13, color: AppColors.listDesc)
                      : const TextStyle(fontSize: 14, color: AppColors.listDesc),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onPressed: onSend,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
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
