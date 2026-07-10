// Author: eduino
// 라우팅 흐름 (§5.1): 스플래시 → 키트 선택(최초 1회) → 연결 → 메인 허브.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/connect/connect_screen.dart';
import '../features/hub/hub_screen.dart';
import '../features/kit/kit_select_screen.dart';
import '../features/splash/splash_screen.dart';

abstract class Routes {
  static const splash = '/';
  static const kit = '/kit';
  static const connect = '/connect';
  static const hub = '/hub';
}

/// GoRouter 를 보유. 화면들은 각자 Consumer 로 provider 에 접근한다.
class GoRouterHolder {
  GoRouterHolder() {
    router = GoRouter(
      initialLocation: Routes.splash,
      routes: [
        GoRoute(
          path: Routes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.kit,
          builder: (context, state) => const KitSelectScreen(),
        ),
        GoRoute(
          path: Routes.connect,
          builder: (context, state) => const ConnectScreen(),
        ),
        GoRoute(
          path: Routes.hub,
          builder: (context, state) => const HubScreen(),
        ),
      ],
    );
  }

  late final GoRouter router;

  void dispose() => router.dispose();
}
