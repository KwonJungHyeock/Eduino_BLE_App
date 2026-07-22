// Author: eduino
// 개별 기능 화면 공통 뼈대: 앱바(뒤로가기·제목·도움말?) + 연결 상태바 + 본문.
// 헤더 통일(지시서 0.3): 모든 기능 화면 = "‹ 제목" + 우측 "?" 도움말.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../app/theme.dart';
import '../providers/bt_providers.dart';
import 'empty_state.dart';
import 'status_bar.dart';

class ModeScaffold extends ConsumerWidget {
  const ModeScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showStatusBar = true,
    this.requireConnection = true,
    this.rc = false,
    this.help,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showStatusBar;

  /// 미연결이면 상단에 "먼저 블루투스 연결하기" CTA 배너를 띄운다(B1).
  final bool requireConnection;

  /// RC(교구) 주행 화면이면 연결 CTA 를 코랄 accent 로(모드 색 통일 · A2).
  final bool rc;

  /// 우측 "?" 를 누르면 보여줄 도움말(없으면 기본 안내).
  final String? help;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionProvider).isConnected;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '도움말',
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showStatusBar) const StatusBar(),
          // 미연결이면 길을 여는 CTA 배너(단순 비활성 금지 · B1).
          if (requireConnection && !connected)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.md, 12, Gap.md, 0),
              child: ConnectCtaBanner(
                accent: rc ? AppColors.accent : AppColors.signal,
                onConnect: () => context.push(Routes.connect),
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline,
                      size: 20, color: AppColors.signal),
                  Gap.w8,
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.listTitle)),
                ],
              ),
              Gap.h12,
              Text(
                help ?? '이 화면의 기능을 사용해 보세요. 먼저 상단에서 블루투스를 연결하면 실제 동작을 확인할 수 있어요.',
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: AppColors.listDesc),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
