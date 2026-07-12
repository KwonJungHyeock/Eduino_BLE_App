// Author: eduino
// 위젯 스모크·동작 테스트 — 커스텀 위젯이 예외 없이 렌더되고 핵심 동작이 맞는지 검증.
// (골든/픽셀 테스트는 baseline 이미지가 필요해 로컬에서 --update-goldens 로 생성 후 추가.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eduino_rc/widgets/brand_mark.dart';
import 'package:eduino_rc/widgets/circuit.dart';
import 'package:eduino_rc/widgets/direction_dial.dart';
import 'package:eduino_rc/widgets/empty_state.dart';
import 'package:eduino_rc/widgets/kit_illustration.dart';
import 'package:eduino_rc/widgets/line_sensor_indicator.dart';
import 'package:eduino_rc/widgets/pressable.dart';
import 'package:eduino_rc/widgets/sparkline.dart';
import 'package:eduino_rc/widgets/speed_gauge.dart';
import 'package:eduino_rc/widgets/success_check.dart';

Future<void> _host(WidgetTester t, Widget w, {double? width}) async {
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: width == null ? w : SizedBox(width: width, child: w),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('BrandMark 렌더', (t) async {
    await _host(t, const BrandMark(size: 100));
    expect(find.byType(BrandMark), findsOneWidget);
  });

  testWidgets('KitIllustration 모든 아트 렌더', (t) async {
    for (final a in KitArt.values) {
      await _host(t, KitIllustration(art: a, size: 96));
      expect(find.byType(KitIllustration), findsOneWidget);
    }
  });

  testWidgets('Sparkline 데이터 렌더', (t) async {
    await _host(t, const Sparkline(values: [1, 2, 3, 2, 4]), width: 120);
    expect(find.byType(Sparkline), findsOneWidget);
  });

  testWidgets('DirectionDial 활성/비활성 렌더', (t) async {
    await _host(t, const DirectionDial(angle: 0));
    expect(find.byType(DirectionDial), findsOneWidget);
    await _host(t, const DirectionDial(angle: null));
    expect(find.byType(DirectionDial), findsOneWidget);
  });

  testWidgets('SuccessCheck 재생 완료', (t) async {
    await _host(t, const SuccessCheck(size: 80));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(seconds: 1)); // 컨트롤러 종료 대기
    expect(find.byType(SuccessCheck), findsOneWidget);
  });

  testWidgets('NodeRailHeader 라벨 표시', (t) async {
    await _host(t, const NodeRailHeader('블루투스 실습'), width: 240);
    expect(find.text('블루투스 실습'), findsOneWidget);
  });

  testWidgets('CircuitAccent 렌더', (t) async {
    await _host(t, const CircuitAccent());
    expect(find.byType(CircuitAccent), findsOneWidget);
  });

  testWidgets('SignalTrace 미연결 렌더', (t) async {
    await _host(t, const SignalTrace(connected: false), width: 220);
    expect(find.text('APP'), findsOneWidget);
  });

  testWidgets('EmptyState 제목·액션', (t) async {
    var tapped = false;
    await _host(
      t,
      EmptyState(
        title: '교구를 선택하세요',
        message: '안내 문구',
        actionLabel: '선택',
        onAction: () => tapped = true,
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('교구를 선택하세요'), findsOneWidget);
    await t.tap(find.text('선택'));
    expect(tapped, isTrue);
  });

  testWidgets('LineSensorIndicator 2개는 중앙 숨김', (t) async {
    await _host(t,
        const LineSensorIndicator(line: (l: 1, c: 0, r: 1), count: 2),
        width: 240);
    expect(find.text('C'), findsNothing);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });

  testWidgets('LineSensorIndicator 3개는 중앙 표시', (t) async {
    await _host(t,
        const LineSensorIndicator(line: (l: 1, c: 0, r: 1), count: 3),
        width: 240);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('SpeedGauge 렌더', (t) async {
    await _host(t, const SpeedGauge(value: 42));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(SpeedGauge), findsOneWidget);
  });

  testWidgets('Pressable onTap 동작', (t) async {
    var tapped = false;
    await _host(
      t,
      Pressable(
        onTap: () => tapped = true,
        child: const SizedBox(width: 80, height: 80),
      ),
    );
    await t.tap(find.byType(Pressable));
    expect(tapped, isTrue);
  });

  testWidgets('RiseIn 자식 렌더', (t) async {
    await _host(t, const RiseIn(child: Text('hello')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('hello'), findsOneWidget);
  });
}
