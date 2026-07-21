// Author: eduino
// 앱 사용 목적(모드) — 온보딩에서 먼저 고른다.
//   lab : 일반 블루투스 기능(연결·통신 실습)
//   kit : 교구 학습(RC카·스마트 교구 제어)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';

enum AppMode { lab, kit }

const String _modePrefKey = 'eduino.appmode';

class AppModeNotifier extends AsyncNotifier<AppMode?> {
  @override
  Future<AppMode?> build() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_modePrefKey);
    if (s == null) return null;
    return AppMode.values.firstWhere((m) => m.name == s,
        orElse: () => AppMode.kit);
  }

  Future<void> select(AppMode mode) async {
    state = AsyncData(mode);
    final p = await SharedPreferences.getInstance();
    await p.setString(_modePrefKey, mode.name);
  }
}

final appModeProvider =
    AsyncNotifierProvider<AppModeNotifier, AppMode?>(AppModeNotifier.new);

extension AppModeInfo on AppMode {
  String get title => this == AppMode.lab ? '블루투스 실습' : '교구 학습';
  String get desc => this == AppMode.lab
      ? '연결·시리얼·AT 커맨드로 통신 원리 학습'
      : 'RC카·스마트 팩토리·홈·팜을 앱으로 제어·체험';
  IconData get icon =>
      this == AppMode.lab ? Icons.bluetooth : Icons.smart_toy_outlined;

  /// 모드 색 토큰 — 교구 학습=코랄, 블루투스 실습=블루. 앱 전역(모드 배너 등)에서 동일 사용.
  Color get color => this == AppMode.lab ? AppColors.signal : AppColors.accent;
}
