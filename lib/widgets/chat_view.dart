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
    // 연속 동일 라인(예: 보드가 1초마다 흘리는 TH:28,49 텔레메트리)을 한 말풍선으로
    // 접어 ×N 으로 표기 — 내가 주고받은 메시지가 반복 수신에 묻히지 않게 한다(데이터는 보존).
    final groups = <_Group>[];
    for (final e in entries) {
      if (groups.isNotEmpty &&
          groups.last.dir == e.dir &&
          groups.last.text == e.text) {
        groups.last.count++;
        groups.last.lastMs = e.atMillis;
      } else {
        groups.add(_Group(e.dir, e.text, e.atMillis));
      }
    }
    ref.listen(terminalProvider, (_, __) => _scrollToEnd());

    return Column(
      children: [
        // 미연결 땐 상단 CTA 배너(ModeScaffold)로 안내가 끝나므로 인포 배너는 숨기고,
        // 연결되면 CTA 가 사라지는 대신 인포 배너를 노출한다(순서 교대 · 3차 항목1).
        if (connected) HintBanner(widget.hint),
        Expanded(
          child: Container(
            color: const Color(0xFFEDF1F6),
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.signal.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.emptyIcon,
                                size: 32, color: AppColors.signal),
                          ),
                          const SizedBox(height: 16),
                          // 연결 시에만 유도 제목 노출. 미연결이면 상단 CTA 배너와
                          // 겹치지 않도록 "연결되면 표시" 한 줄만 남긴다(항목1).
                          if (connected) ...[
                            const Text(
                              '첫 메시지를 보내 보세요',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.listTitle),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            connected
                                ? '아래 입력창이나 빠른 문장 칩으로 보낼 수 있어요.'
                                : '연결되면 주고받은 내용이 여기에 표시돼요.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: AppColors.listDesc),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    itemCount: groups.length,
                    itemBuilder: (context, i) => _SlideIn(
                      key: ValueKey(groups[i].firstMs),
                      child: _Bubble(
                          entry: TerminalEntry(
                              groups[i].dir, groups[i].text, groups[i].lastMs),
                          count: groups[i].count,
                          mono: widget.mono,
                          showTxRx: widget.showTxRx),
                    ),
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
                  padding: const EdgeInsets.only(left: 16),
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

/// 메시지 등장 애니메이션(C3) — 새 말풍선이 아래에서 살짝 슬라이드+페이드.
/// ValueKey(atMillis) 로 매칭돼 이미 표시된 말풍선은 다시 재생되지 않는다.
class _SlideIn extends StatefulWidget {
  const _SlideIn({super.key, required this.child});
  final Widget child;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// 연속 동일 라인 묶음(반복 텔레메트리 접기용). firstMs=키 안정, lastMs=시각 표시.
class _Group {
  _Group(this.dir, this.text, this.firstMs) : lastMs = firstMs;
  final LogDir dir;
  final String text;
  final int firstMs;
  int lastMs;
  int count = 1;
}

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.entry,
      required this.mono,
      required this.showTxRx,
      this.count = 1});
  final TerminalEntry entry;
  final bool mono;
  final bool showTxRx;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (entry.dir == LogDir.system) {
      // 상태 칩(A3) — 연결됨=민트 / 진행 중=노랑 / 해제=회색 dot 로 한눈에.
      final t = entry.text;
      final Color? dot = t.startsWith('연결됨')
          ? AppColors.mint
          : t.contains('중')
              ? AppColors.warn
              : t.contains('해제')
                  ? AppColors.chipGrayIcon
                  : null;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(entry.text,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.listDesc)),
              ],
            ),
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
            if (showTxRx || count > 1) ...[
              Text(
                [
                  if (showTxRx) mine ? 'TX · 보냄' : 'RX · 받음',
                  if (count > 1) '×$count',
                ].join('  '),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
