// Author: eduino
// 라우팅 흐름 (재구성): 인트로 → 홈 메뉴 → (연결 / AT커맨드 / 통신기초예제 / 컨트롤러 / 에듀이노 교구).
// 컨트롤러 메뉴에서 조이스틱·방향·자율 모드를 push. 개별 모드는 ModeScaffold 로 감싼다.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/autonomous/autonomous_screen.dart';
import '../features/basics/basics_screen.dart';
import '../features/connect/connect_screen.dart';
import '../features/controller/controller_menu_screen.dart';
import '../features/controller/controller_screen.dart';
import '../features/home/home_screen.dart';
import '../features/joystick/joystick_screen.dart';
import '../features/kit/kit_select_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/terminal/terminal_screen.dart';
import '../widgets/mode_scaffold.dart';

abstract class Routes {
  static const intro = '/';
  static const home = '/home';
  static const connect = '/connect';
  static const kit = '/kit';
  static const terminal = '/terminal';
  static const basics = '/basics';
  static const controller = '/controller';
  static const joystick = '/controller/joystick';
  static const dpad = '/controller/dpad';
  static const auto = '/controller/auto';
}

class GoRouterHolder {
  GoRouterHolder() {
    router = GoRouter(
      initialLocation: Routes.intro,
      routes: [
        GoRoute(
          path: Routes.intro,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.connect,
          builder: (context, state) => const ConnectScreen(),
        ),
        GoRoute(
          path: Routes.kit,
          builder: (context, state) => const KitSelectScreen(),
        ),
        GoRoute(
          path: Routes.terminal,
          builder: (context, state) =>
              const ModeScaffold(title: 'AT 커맨드', child: TerminalScreen()),
        ),
        GoRoute(
          path: Routes.basics,
          builder: (context, state) =>
              const ModeScaffold(title: '통신 기초 예제', child: BasicsScreen()),
        ),
        GoRoute(
          path: Routes.controller,
          builder: (context, state) => const ControllerMenuScreen(),
        ),
        GoRoute(
          path: Routes.joystick,
          builder: (context, state) =>
              const ModeScaffold(title: '조이스틱', child: JoystickScreen()),
        ),
        GoRoute(
          path: Routes.dpad,
          builder: (context, state) =>
              const ModeScaffold(title: '방향 버튼', child: ControllerScreen()),
        ),
        GoRoute(
          path: Routes.auto,
          builder: (context, state) => const ModeScaffold(
              title: '자율주행 · 실험', child: AutonomousScreen()),
        ),
      ],
    );
  }

  late final GoRouter router;

  void dispose() => router.dispose();
}
