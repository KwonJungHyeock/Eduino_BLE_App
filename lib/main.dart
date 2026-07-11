// Author: eduino
// 앱 진입점. Neo Cockpit 테마 + Riverpod + go_router.
// 안전 우선: 백그라운드 전환 시 즉시 STP (§4.4).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'providers/car_controller.dart';
import 'providers/connection_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EduinoApp()));
}

class EduinoApp extends ConsumerStatefulWidget {
  const EduinoApp({super.key});

  @override
  ConsumerState<EduinoApp> createState() => _EduinoAppState();
}

class _EduinoAppState extends ConsumerState<EduinoApp>
    with WidgetsBindingObserver {
  late final GoRouterHolder _routerHolder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routerHolder = GoRouterHolder();
    // CarController·ConnectionManager 를 즉시 인스턴스화(하트비트·연결/재연결 리스너 활성화).
    ref.read(carControllerProvider);
    ref.read(connectionManagerProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routerHolder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 백그라운드/비활성 전환 → 즉시 안전 정지 (§4.4).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ref.read(carControllerProvider).emergencyStop();
    } else if (state == AppLifecycleState.resumed) {
      // 복귀 시 끊겨 있으면 지난 기기로 자동 재연결 시도.
      ref.read(connectionManagerProvider).onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EDUINO RC',
      debugShowCheckedModeBanner: false,
      theme: buildNeoCockpitTheme(),
      routerConfig: _routerHolder.router,
      builder: (context, child) {
        // 시스템 UI 다크 톤 고정.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
