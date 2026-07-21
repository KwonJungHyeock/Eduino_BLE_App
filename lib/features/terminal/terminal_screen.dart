// Author: eduino
// 터미널 (§5.9): 송/수신 로그(송신=회색, 수신=녹색), 입력창→RAW 전송, AT 예제 버튼.
// "보이는 통신" — 오가는 명령을 그대로 보여주는 교보재.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../providers/module_providers.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // 모듈별 AT 예제 (미연결 AT 모드에서만 모듈이 응답 — 화면 안내로 교육 포인트화, §5.9).
  static const List<String> _atHm10 = ['AT', 'AT+NAME?', 'AT+ROLE?', 'AT+RESET'];
  static const List<String> _atHc06 = ['AT', 'AT+VERSION', 'AT+NAME', 'AT+BAUD4'];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    HapticFeedback.selectionClick();
    // 문자 그대로 전송(AT/일반 시리얼). RAW: 프레임을 붙이지 않는다.
    ref.read(carControllerProvider).sendPlain(t);
    _input.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(terminalProvider);
    final module = ref.watch(moduleProvider).valueOrNull ?? BtModule.ble;
    final examples = module == BtModule.spp ? _atHc06 : _atHm10;
    ref.listen(terminalProvider, (_, __) => _scrollToEnd());

    return Column(
      children: [
        // AT 안내 배너 — 연결 후 보낸 AT 는 아두이노로 전달될 뿐 모듈 설정은 안 바뀜.
        Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: Gap.md, vertical: Gap.sm),
          child: Text(
            'ℹ AT 명령은 미연결(AT 모드)에서만 모듈이 응답합니다. 연결 후엔 아두이노로 전달만 됩니다.',
            style: AppType.mono(size: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFEDF1F6),
            child: log.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.terminal,
                            size: 40, color: AppColors.chevron),
                        const SizedBox(height: 12),
                        const Text('송수신 로그가 여기에 표시됩니다.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.listDesc)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    itemCount: log.length,
                    itemBuilder: (context, i) => _LogRow(entry: log[i]),
                  ),
          ),
        ),
        // AT 예제 버튼
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            itemCount: examples.length + 1,
            separatorBuilder: (_, __) => Gap.w8,
            itemBuilder: (context, i) {
              if (i == examples.length) {
                return _pill('지우기', Icons.clear_all,
                    () => ref.read(terminalProvider.notifier).clear());
              }
              final at = examples[i];
              return _pill(at, null, () => _send(at));
            },
          ),
        ),
        _InputBar(controller: _input, onSend: () => _send(_input.text)),
      ],
    );
  }

  Widget _pill(String label, IconData? icon, VoidCallback onTap) => Center(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: onTap,
          icon: icon == null
              ? const SizedBox.shrink()
              : Icon(icon, size: 14, color: AppColors.textMuted),
          label: Text(label, style: AppType.mono(size: 12)),
        ),
      );
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});
  final TerminalEntry entry;

  @override
  Widget build(BuildContext context) {
    // 시스템 로그(연결 상태 등)는 가운데 옅은 안내 칩.
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
                style: const TextStyle(fontSize: 11, color: AppColors.listDesc)),
          ),
        ),
      );
    }
    final mine = entry.dir == LogDir.out; // 송신=오른쪽 파랑, 수신=왼쪽 흰
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
        // AT/시리얼 명령은 데이터 → 모노 유지.
        child: Text(entry.text,
            style: AppType.mono(
                size: 13.5,
                height: 1.3,
                color: mine ? Colors.white : AppColors.listTitle)),
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

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
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
                style: AppType.mono(size: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'RAW 명령 입력 (예: AT+NAME?)',
                  hintStyle:
                      AppType.mono(size: 13, color: AppColors.listDesc),
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
              onPressed: onSend,
              style: FilledButton.styleFrom(
                minimumSize: const Size(52, 48),
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
