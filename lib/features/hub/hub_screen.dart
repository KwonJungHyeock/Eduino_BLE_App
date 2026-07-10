// Author: eduino
// 메인 허브 (§5.1). 하단 탭으로 모드 전환. 상단 상태바 상시 노출. 연결 끊기면 연결 화면으로.
// 현재 스코프(P0–P5): 조이스틱 · 방향버튼 · 자율주행 · 터미널. (LED/기울기/음성/미션은 P6+)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/bt/bt_transport.dart';
import '../../providers/bt_providers.dart';
import '../../providers/kit_providers.dart';
import '../../widgets/status_bar.dart';
import '../autonomous/autonomous_screen.dart';
import '../controller/controller_screen.dart';
import '../joystick/joystick_screen.dart';
import '../terminal/terminal_screen.dart';

class _Tab {
  const _Tab(this.icon, this.label, this.builder);
  final IconData icon;
  final String label;
  final Widget Function() builder;
}

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  int _index = 0;

  List<_Tab> get _tabs => const [
        _Tab(Icons.gamepad_outlined, '조이스틱', _buildJoystick),
        _Tab(Icons.control_camera_outlined, '방향', _buildController),
        _Tab(Icons.auto_mode_outlined, '자율주행', _buildAutonomous),
        _Tab(Icons.terminal_outlined, '터미널', _buildTerminal),
      ];

  static Widget _buildJoystick() => const JoystickScreen();
  static Widget _buildController() => const ControllerScreen();
  static Widget _buildAutonomous() => const AutonomousScreen();
  static Widget _buildTerminal() => const TerminalScreen();

  @override
  Widget build(BuildContext context) {
    final kit = ref.watch(kitProfileProvider).valueOrNull;

    // 연결이 끊기면 연결 화면으로 복귀(안전·명확성).
    ref.listen<BtConnectionState>(connectionProvider, (prev, next) {
      if (next == BtConnectionState.disconnected && mounted) {
        context.go(Routes.connect);
      }
    });

    final tabs = _tabs;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: Gap.md,
        title: Row(
          children: [
            Text(tabs[_index].label),
            Gap.w8,
            if (kit != null)
              Text('· ${kit.name}',
                  style: AppType.mono(size: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '연결 해제',
            icon: const Icon(Icons.link_off),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await ref.read(bleTransportProvider).disconnect();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [for (final t in tabs) t.builder()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomTabs(
        tabs: tabs,
        index: _index,
        onChanged: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: _TabItem(tab: tabs[i], selected: i == index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected});
  final _Tab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.signal : AppColors.textMuted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(tab.icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(tab.label,
            style: AppType.mono(
              size: 11,
              color: color,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ],
    );
  }
}
