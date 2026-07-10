// Author: eduino
// 키트 프로파일 + 능력(컨트롤) 모델 (차별 C).
// "주행 앱"이 아니라 "교구 제어 플랫폼" — 각 킷이 지원하는 컨트롤 컴포넌트로 제어판을 자동 구성한다.
//   RC카(2휠/메탈/4휠) : 주행 + LED + 센서
//   스마트 팩토리/홈/팜 : 서보·릴레이·LCD·센서 조합

import 'package:flutter/material.dart';

enum KitType { twoWheel, metal, fourWheel, smartFactory, smartHome, smartFarm }

/// 킷 분류 — 홈에서 RC / 교구 갈래로 나눈다.
enum KitCategory { rcCar, appliance }

/// 제어 컴포넌트 종류. 제어판이 이걸 보고 위젯을 렌더한다.
enum ControlKind {
  drive, // 주행 컨트롤러(조이스틱/방향/기울기/음성) 진입
  ledToggle, // LED:1/0 (보드 13핀)
  relayToggle, // ACT:<id>,0/1 (팬·펌프·조명·컨베이어)
  pwmSlider, // ACT:<id>,0-100 (컨베이어 속도 등)
  servoSlider, // SRV:<id>,0-180 (도어·분류)
  lcdText, // LCD:0,<text>
  sensorReadout, // 텔레메트리 표시(DST/LIN/TMP/HUM/SOL/LUX/OBJ)
}

class ControlSpec {
  const ControlSpec({
    required this.kind,
    required this.label,
    this.icon = Icons.tune,
    this.id = 0,
    this.sensorKey,
    this.unit = '',
    this.min = 0,
    this.max = 180,
  });

  final ControlKind kind;
  final String label;
  final IconData icon;
  final int id;
  final String? sensorKey; // sensorReadout 전용 (TMP/HUM/…), 'DST'/'LIN'은 특수
  final String unit;
  final int min;
  final int max;
}

class KitProfile {
  const KitProfile({
    required this.type,
    required this.category,
    required this.name,
    required this.tagline,
    required this.assetImage,
    required this.controls,
    this.hasLineSensor = false,
    this.hasUltrasonic = false,
    this.motorSummary = '',
  });

  final KitType type;
  final KitCategory category;
  final String name;
  final String tagline;
  final String assetImage;
  final List<ControlSpec> controls;

  // RC 전용 부가 정보(주행 화면 게이팅에 사용).
  final bool hasLineSensor;
  final bool hasUltrasonic;
  final String motorSummary;

  bool get isRc => category == KitCategory.rcCar;
  String get storageKey => type.name;

  static KitProfile forType(KitType type) {
    switch (type) {
      case KitType.twoWheel:
        return const KitProfile(
          type: KitType.twoWheel,
          category: KitCategory.rcCar,
          name: '2휠 RC카',
          tagline: 'H-10 · IR 라인센서 + 초음파',
          assetImage: 'assets/kits/two_wheel.jpg',
          hasLineSensor: true,
          hasUltrasonic: true,
          motorSummary: 'DC×2 · L298N · 좌/우',
          controls: [
            ControlSpec(kind: ControlKind.drive, label: '주행 컨트롤러', icon: Icons.sports_esports),
            ControlSpec(kind: ControlKind.ledToggle, label: 'LED (13번 핀)', icon: Icons.lightbulb),
            ControlSpec(kind: ControlKind.sensorReadout, label: '초음파 거리', icon: Icons.straighten, sensorKey: 'DST', unit: 'cm'),
          ],
        );
      case KitType.metal:
        return const KitProfile(
          type: KitType.metal,
          category: KitCategory.rcCar,
          name: '메탈 RC카',
          tagline: '초음파 장애물 회피 (IR 라인센서 없음)',
          assetImage: 'assets/kits/metal.png',
          hasLineSensor: false,
          hasUltrasonic: true,
          motorSummary: 'DC×2 · L298N · 좌/우',
          controls: [
            ControlSpec(kind: ControlKind.drive, label: '주행 컨트롤러', icon: Icons.sports_esports),
            ControlSpec(kind: ControlKind.ledToggle, label: 'LED (13번 핀)', icon: Icons.lightbulb),
            ControlSpec(kind: ControlKind.sensorReadout, label: '초음파 거리', icon: Icons.straighten, sensorKey: 'DST', unit: 'cm'),
          ],
        );
      case KitType.fourWheel:
        return const KitProfile(
          type: KitType.fourWheel,
          category: KitCategory.rcCar,
          name: '4휠 스마트카',
          tagline: 'IR 라인센서 + 초음파 · 4륜 구동',
          assetImage: 'assets/kits/four_wheel.jpg',
          hasLineSensor: true,
          hasUltrasonic: true,
          motorSummary: 'DC×4 · L298N×2 · 좌2·우2 병렬',
          controls: [
            ControlSpec(kind: ControlKind.drive, label: '주행 컨트롤러', icon: Icons.sports_esports),
            ControlSpec(kind: ControlKind.ledToggle, label: 'LED (13번 핀)', icon: Icons.lightbulb),
            ControlSpec(kind: ControlKind.sensorReadout, label: '초음파 거리', icon: Icons.straighten, sensorKey: 'DST', unit: 'cm'),
          ],
        );
      case KitType.smartFactory:
        return const KitProfile(
          type: KitType.smartFactory,
          category: KitCategory.appliance,
          name: '스마트 팩토리',
          tagline: '컨베이어 · 분류 서보 · 물체 감지',
          assetImage: 'assets/kits/smart_factory.png',
          controls: [
            ControlSpec(kind: ControlKind.pwmSlider, label: '컨베이어 속도', icon: Icons.view_stream, id: 0, unit: '%', min: 0, max: 100),
            ControlSpec(kind: ControlKind.servoSlider, label: '분류 서보', icon: Icons.swap_horiz, id: 0, min: 0, max: 180),
            ControlSpec(kind: ControlKind.sensorReadout, label: '물체 감지', icon: Icons.sensors, sensorKey: 'OBJ'),
          ],
        );
      case KitType.smartHome:
        return const KitProfile(
          type: KitType.smartHome,
          category: KitCategory.appliance,
          name: '스마트 홈 키트',
          tagline: '현관문 서보 · 조명 · LCD',
          assetImage: 'assets/kits/smart_home.png',
          controls: [
            ControlSpec(kind: ControlKind.servoSlider, label: '현관문 (서보)', icon: Icons.meeting_room, id: 0, min: 0, max: 180),
            ControlSpec(kind: ControlKind.relayToggle, label: '조명', icon: Icons.light, id: 1),
            ControlSpec(kind: ControlKind.lcdText, label: 'LCD 메시지', icon: Icons.message),
            ControlSpec(kind: ControlKind.sensorReadout, label: '조도', icon: Icons.wb_sunny, sensorKey: 'LUX'),
          ],
        );
      case KitType.smartFarm:
        return const KitProfile(
          type: KitType.smartFarm,
          category: KitCategory.appliance,
          name: '스마트 팜 온실',
          tagline: '환기팬 · 워터펌프 · 조명 · 온습도/토양',
          assetImage: 'assets/kits/smart_farm.png',
          controls: [
            ControlSpec(kind: ControlKind.relayToggle, label: '환기팬', icon: Icons.air, id: 0),
            ControlSpec(kind: ControlKind.relayToggle, label: '워터펌프', icon: Icons.water_drop, id: 1),
            ControlSpec(kind: ControlKind.relayToggle, label: '조명', icon: Icons.light, id: 2),
            ControlSpec(kind: ControlKind.sensorReadout, label: '온도', icon: Icons.thermostat, sensorKey: 'TMP', unit: '°C'),
            ControlSpec(kind: ControlKind.sensorReadout, label: '습도', icon: Icons.water, sensorKey: 'HUM', unit: '%'),
            ControlSpec(kind: ControlKind.sensorReadout, label: '토양수분', icon: Icons.grass, sensorKey: 'SOL'),
            ControlSpec(kind: ControlKind.lcdText, label: 'LCD 메시지', icon: Icons.message),
          ],
        );
    }
  }

  static const List<KitType> rcKits = [
    KitType.twoWheel,
    KitType.metal,
    KitType.fourWheel,
  ];

  static const List<KitType> applianceKits = [
    KitType.smartFactory,
    KitType.smartHome,
    KitType.smartFarm,
  ];

  static const List<KitType> all = [...rcKits, ...applianceKits];

  IconData get fallbackIcon {
    switch (type) {
      case KitType.twoWheel:
        return Icons.two_wheeler_outlined;
      case KitType.metal:
        return Icons.directions_car_outlined;
      case KitType.fourWheel:
        return Icons.airport_shuttle_outlined;
      case KitType.smartFactory:
        return Icons.precision_manufacturing_outlined;
      case KitType.smartHome:
        return Icons.home_outlined;
      case KitType.smartFarm:
        return Icons.local_florist_outlined;
    }
  }
}
