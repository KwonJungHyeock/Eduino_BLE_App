// Author: eduino
// 공용 확인 다이얼로그 — 되돌리기 어려운/안전 관련 동작 전에 한 번 확인.

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// true = 사용자가 확인. danger=true 면 확인 버튼을 코랄(경고)로.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          style: danger
              ? FilledButton.styleFrom(backgroundColor: AppColors.accent)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}
