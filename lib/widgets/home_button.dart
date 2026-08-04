// Author: eduino
// 전역 홈 버튼(QA-3 C): 어느 화면에서든 홈(교구 고르기/홈 메뉴)으로 1탭 복귀.
// go_router 루트 이동(go)으로 중간 push 스택을 정리한다.
// ★ BLE 연결 상태와 "소개 스킵" 플래그(SharedPreferences)는 건드리지 않음 — 홈 이동만 수행.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../app/theme.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_rounded),
      color: AppColors.signal,
      tooltip: '홈으로',
      onPressed: () => context.go(Routes.home),
    );
  }
}
