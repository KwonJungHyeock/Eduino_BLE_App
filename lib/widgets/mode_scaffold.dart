// Author: eduino
// 개별 기능 화면 공통 뼈대: 앱바(뒤로가기·제목·도움말?) + 연결 상태바 + 본문.
// 헤더 통일(지시서 0.3): 모든 기능 화면 = "‹ 제목" + 우측 "?" 도움말.

import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'status_bar.dart';

class ModeScaffold extends StatelessWidget {
  const ModeScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showStatusBar = true,
    this.help,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showStatusBar;

  /// 우측 "?" 를 누르면 보여줄 도움말(없으면 기본 안내).
  final String? help;

  @override
  Widget build(BuildContext context) {
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
