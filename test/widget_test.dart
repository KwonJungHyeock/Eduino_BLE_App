// Author: eduino
// flutter create 가 자동 생성하는 기본 카운터 테스트(존재하지 않는 MyApp 참조)를
// 덮어써 CI 컴파일 실패를 막기 위한 파일. 실제 테스트는 아래 참고.
//   · 위젯 렌더/동작: widgets_test.dart
//   · 프로토콜 인/디코더: protocol_test.dart
//   · 골든(스캐폴드): golden_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('테스트 스위트 로드 확인', () {
    expect(1 + 1, 2);
  });
}
