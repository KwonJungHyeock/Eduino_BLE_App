// Author: eduino
// 라우팅 흐름 (재구성): 인트로 → 홈 메뉴 → (연결 / AT커맨드 / 통신기초예제 / 컨트롤러 / 에듀이노 교구).
// 컨트롤러 메뉴에서 조이스틱·방향·자율 모드를 push. 개별 모드는 ModeScaffold 로 감싼다.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/autonomous/autonomous_screen.dart';
import '../features/autonomous/line_trace_screen.dart';
import '../features/basics/serial_chat_screen.dart';
import '../features/connect/connect_screen.dart';
import '../features/control/control_panel_screen.dart';
import '../features/controller/controller_menu_screen.dart';
import '../features/controller/controller_screen.dart';
import '../features/help/help_screen.dart';
import '../features/help/privacy_screen.dart';
import '../features/home/home_screen.dart';
import '../features/joystick/joystick_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/led/led_screen.dart';
import '../features/missions/missions_screen.dart';
import '../features/mode/mode_select_screen.dart';
import '../features/motor/motor_config_screen.dart';
import '../features/motor/rc_config_screen.dart';
import '../features/onboarding/tutorial_screen.dart';
import '../features/tilt/tilt_screen.dart';
import '../features/voice/voice_screen.dart';
import '../features/kit/kit_learn_screen.dart';
import '../features/kit/kit_select_screen.dart';
import '../features/module/module_select_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/terminal/terminal_screen.dart';
import '../widgets/mode_scaffold.dart';

abstract class Routes {
  static const intro = '/';
  static const tutorial = '/tutorial';
  static const mode = '/mode';
  static const module = '/module';
  static const home = '/home';
  static const connect = '/connect';
  static const kit = '/kit';
  static const kitLearn = '/kit-learn';
  static const control = '/control';
  static const motor = '/motor';
  static const rcConfig = '/rc-config';
  static const terminal = '/terminal';
  static const basics = '/basics';
  static const controller = '/controller';
  static const joystick = '/controller/joystick';
  static const dpad = '/controller/dpad';
  static const auto = '/controller/auto';
  static const led = '/controller/led';
  static const line = '/controller/line';
  static const tilt = '/controller/tilt';
  static const voice = '/controller/voice';
  static const missions = '/missions';
  static const learn = '/learn';
  static const help = '/help';
  static const privacy = '/privacy';
}

// 온보딩 화면 전환용 크로스페이드 페이지(인트로→튜토리얼 등 끊김 없이 인계).
CustomTransitionPage<void> _fadePage(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

class GoRouterHolder {
  GoRouterHolder() {
    router = GoRouter(
      initialLocation: Routes.intro,
      routes: [
        GoRoute(
          path: Routes.intro,
          builder: (context, state) => const SplashScreen(),
        ),
        // 온보딩 체인은 인트로에서 부드럽게 크로스페이드로 인계(끊김 방지).
        GoRoute(
          path: Routes.tutorial,
          pageBuilder: (context, state) => _fadePage(const TutorialScreen()),
        ),
        GoRoute(
          path: Routes.mode,
          pageBuilder: (context, state) => _fadePage(const ModeSelectScreen()),
        ),
        GoRoute(
          path: Routes.module,
          pageBuilder: (context, state) =>
              _fadePage(const ModuleSelectScreen()),
        ),
        GoRoute(
          path: Routes.home,
          pageBuilder: (context, state) => _fadePage(const HomeScreen()),
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
          path: Routes.kitLearn,
          builder: (context, state) => const KitLearnScreen(),
        ),
        GoRoute(
          path: Routes.control,
          builder: (context, state) => const ControlPanelScreen(),
        ),
        GoRoute(
          path: Routes.motor,
          builder: (context, state) => const MotorConfigScreen(),
        ),
        GoRoute(
          path: Routes.rcConfig,
          builder: (context, state) => const RcConfigScreen(),
        ),
        GoRoute(
          path: Routes.terminal,
          builder: (context, state) =>
              const ModeScaffold(title: 'AT 커맨드', child: TerminalScreen()),
        ),
        GoRoute(
          path: Routes.basics,
          builder: (context, state) =>
              const ModeScaffold(title: '시리얼 통신 채팅', child: SerialChatScreen()),
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
        GoRoute(
          path: Routes.led,
          builder: (context, state) =>
              const ModeScaffold(title: 'LED 제어', child: LedScreen()),
        ),
        GoRoute(
          path: Routes.line,
          builder: (context, state) =>
              const ModeScaffold(title: '라인트레이싱', child: LineTraceScreen()),
        ),
        GoRoute(
          path: Routes.tilt,
          builder: (context, state) =>
              const ModeScaffold(title: '기울기 제어', child: TiltScreen()),
        ),
        GoRoute(
          path: Routes.voice,
          builder: (context, state) =>
              const ModeScaffold(title: '음성 제어', child: VoiceScreen()),
        ),
        GoRoute(
          path: Routes.missions,
          builder: (context, state) =>
              const ModeScaffold(title: '미션 · 챌린지', child: MissionsScreen()),
        ),
        GoRoute(
          path: Routes.learn,
          builder: (context, state) =>
              const ModeScaffold(title: '명령 ↔ 코드', child: LearnScreen()),
        ),
        GoRoute(
          path: Routes.help,
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: Routes.privacy,
          builder: (context, state) => const PrivacyScreen(),
        ),
      ],
    );
  }

  late final GoRouter router;

  void dispose() => router.dispose();
}
