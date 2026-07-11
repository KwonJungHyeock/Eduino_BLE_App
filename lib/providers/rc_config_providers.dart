// Author: eduino
// RC카 설정 — 키트를 따로 선택하지 않고, 컨트롤러 설정에서 휠/센서/핀만 지정한다.
//  · 휠(2/4)  → 라인센서 개수(2/3) 자동 결정
//  · 라인센서 유무(메탈 RC카는 없음)
//  · LED 핀(기본 13, 커스텀)
// 모터 포트는 기존 motorConfigProvider(휠 타입 기반)를 그대로 사용.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/kit/kit_profile.dart';

enum WheelType { two, four }

extension WheelTypeInfo on WheelType {
  String get label => this == WheelType.four ? '4휠 구동' : '2휠 구동';
  int get motorCount => this == WheelType.four ? 4 : 2;

  /// 모터 포트 매핑을 재사용하기 위한 KitType 대응.
  KitType get kitType =>
      this == WheelType.four ? KitType.fourWheel : KitType.twoWheel;
}

class RcConfig {
  const RcConfig({
    this.wheels = WheelType.two,
    this.hasLineSensor = true,
    this.ledPin = 13,
  });

  final WheelType wheels;
  final bool hasLineSensor;
  final int ledPin;

  /// 라인트레이서 센서 개수: 2휠=2, 4휠=3 (없으면 0).
  int get lineSensorCount =>
      hasLineSensor ? (wheels == WheelType.four ? 3 : 2) : 0;

  RcConfig copyWith({WheelType? wheels, bool? hasLineSensor, int? ledPin}) =>
      RcConfig(
        wheels: wheels ?? this.wheels,
        hasLineSensor: hasLineSensor ?? this.hasLineSensor,
        ledPin: ledPin ?? this.ledPin,
      );
}

class RcConfigNotifier extends AsyncNotifier<RcConfig> {
  static const _kWheels = 'eduino.rc.wheels';
  static const _kLine = 'eduino.rc.line';
  static const _kLedPin = 'eduino.rc.ledpin';

  @override
  Future<RcConfig> build() async {
    final p = await SharedPreferences.getInstance();
    return RcConfig(
      wheels: p.getString(_kWheels) == 'four' ? WheelType.four : WheelType.two,
      hasLineSensor: p.getBool(_kLine) ?? true,
      ledPin: p.getInt(_kLedPin) ?? 13,
    );
  }

  Future<void> _save(RcConfig c) async {
    state = AsyncData(c);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kWheels, c.wheels.name);
    await p.setBool(_kLine, c.hasLineSensor);
    await p.setInt(_kLedPin, c.ledPin);
  }

  RcConfig get _current => state.valueOrNull ?? const RcConfig();

  Future<void> setWheels(WheelType w) => _save(_current.copyWith(wheels: w));
  Future<void> setLineSensor(bool v) =>
      _save(_current.copyWith(hasLineSensor: v));
  Future<void> setLedPin(int pin) => _save(_current.copyWith(ledPin: pin));
}

final rcConfigProvider =
    AsyncNotifierProvider<RcConfigNotifier, RcConfig>(RcConfigNotifier.new);
