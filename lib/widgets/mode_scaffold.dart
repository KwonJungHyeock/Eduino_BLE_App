// Author: eduino
// 개별 모드 화면 공통 뼈대: 앱바(뒤로가기·제목) + 상태바 + 본문. 홈에서 push 되는 화면들이 사용.

import 'package:flutter/material.dart';

import 'circuit.dart';
import 'status_bar.dart';

class ModeScaffold extends StatelessWidget {
  const ModeScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showStatusBar = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showStatusBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: CircuitAccent(width: 48)),
          ),
        ],
      ),
      body: BreadboardBackground(
        child: Column(
          children: [
            if (showStatusBar) const StatusBar(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
