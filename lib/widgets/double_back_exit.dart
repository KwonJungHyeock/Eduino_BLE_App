// Author: eduino
// 루트(홈)에서 뒤로가기 처리 — 모달 종료창 대신 "한 번 더 누르면 종료" 스낵바.
// 실수로 한 번 누른 뒤로가기가 앱을 바로 닫거나 창을 띄우지 않아 완성도가 높다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    this.message = '뒤로가기를 한 번 더 누르면 종료됩니다',
    this.window = const Duration(seconds: 2),
  });

  final Widget child;
  final String message;
  final Duration window;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBack != null && now.difference(_lastBack!) <= widget.window) {
          SystemNavigator.pop();
          return;
        }
        _lastBack = now;
        HapticFeedback.selectionClick();
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.message),
            duration: widget.window,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            backgroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: Radii.chip),
          ),
        );
      },
      child: widget.child,
    );
  }
}
