// Author: eduino
// 골든(픽셀) 테스트 스캐폴드 — baseline 이미지가 있어야 동작한다.
//
// 활성화 방법(실기기/PC 에 Flutter 설치된 환경에서):
//   1) 아래 각 테스트의 `skip: _needBaseline` 를 `skip: false` 로 바꾸거나 _needBaseline=false
//   2) flutter test --update-goldens test/golden_test.dart   → test/goldens/*.png 생성
//   3) 생성된 test/goldens/*.png 를 커밋
// 이후 CI(비차단 test 단계)에서 UI 회귀가 픽셀 단위로 잡힌다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eduino_rc/widgets/brand_mark.dart';
import 'package:eduino_rc/widgets/kit_illustration.dart';

// baseline 이미지를 아직 커밋하지 않았으므로 기본 스킵.
const bool _needBaseline = true;

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: RepaintBoundary(child: w)),
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 1200));
}

void main() {
  testWidgets('golden · BrandMark', (t) async {
    await _pump(t, const BrandMark(size: 120));
    await expectLater(
      find.byType(BrandMark),
      matchesGoldenFile('goldens/brand_mark.png'),
    );
  }, skip: _needBaseline);

  testWidgets('golden · KitIllustration(car)', (t) async {
    await _pump(t, const KitIllustration(art: KitArt.car, size: 120));
    await expectLater(
      find.byType(KitIllustration),
      matchesGoldenFile('goldens/kit_car.png'),
    );
  }, skip: _needBaseline);
}
