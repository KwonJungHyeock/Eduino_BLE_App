// Author: eduino
// 키트 프로파일 + 능력(컨트롤) 모델 (차별 C).
// "주행 앱"이 아니라 "교구 제어 플랫폼" — 각 킷이 지원하는 컨트롤 컴포넌트로 제어판을 자동 구성한다.
//   RC카(2휠/메탈/4휠) : 주행 + LED + 센서
//   스마트 팩토리/홈/팜 : 서보·릴레이·LCD·센서 조합

import 'package:flutter/material.dart';

import '../../widgets/kit_illustration.dart';

enum KitType { twoWheel, metal, fourWheel, smartFactory, smartHome, smartFarm }

/// KitType → 커스텀 일러스트(KitArt) 매핑. feature → widget 방향(정상).
KitArt kitArtFor(KitType t) => switch (t) {
      KitType.twoWheel || KitType.metal || KitType.fourWheel => KitArt.car,
      KitType.smartFactory => KitArt.factory,
      KitType.smartHome => KitArt.home,
      KitType.smartFarm => KitArt.farm,
    };

/// 킷 분류 — 홈에서 RC / 교구 갈래로 나눈다.
enum KitCategory { rcCar, appliance }

/// 킷 경험(아키타입) — 카테고리가 어떤 화면 흐름으로 이어지는지(B1).
///   rcController   : RC 3종 선택 → 프로파일 컨트롤러
///   panelCurriculum: 교구 선택 → 제어판 + 강의 커리큘럼
enum KitExperience { rcController, panelCurriculum }

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
    this.wheels = 2,
    this.motorSummary = '',
  });

  final KitType type;
  final KitCategory category;
  final String name;
  final String tagline;
  final String assetImage;
  final List<ControlSpec> controls;

  // RC 전용 부가 정보(주행 화면 게이팅에 사용).
  final bool hasLineSensor; // 라인센서 "기본 내장" 여부(4휠=true). 2휠/메탈=별매 옵션.
  final bool hasUltrasonic;
  final int wheels; // 2 | 4 — 실물 인식용 표시.
  final String motorSummary;

  bool get isRc => category == KitCategory.rcCar;

  /// 이 킷이 이어지는 경험(아키타입 · B1).
  KitExperience get experience => isRc
      ? KitExperience.rcController
      : KitExperience.panelCurriculum;

  // 기능 노출 규칙(spec C/D) — 주행·자율(초음파)은 3종 공통, 라인은 프로파일별.
  bool get capDrive => isRc;
  bool get capAutoUltra => hasUltrasonic;
  bool get capLineTraceBuiltIn => hasLineSensor; // 토글과 별개로 "내장" 여부.
  String get storageKey => type.name;

  static KitProfile forType(KitType type) {
    switch (type) {
      case KitType.twoWheel:
        return const KitProfile(
          type: KitType.twoWheel,
          category: KitCategory.rcCar,
          name: '2휠 교육용 RC카',
          tagline: '투명 바디 · 2륜 구동 (DC×2)',
          assetImage: 'assets/kits/two_wheel.jpg',
          hasLineSensor: false, // 라인센서 별매 옵션 → 토글로 활성.
          hasUltrasonic: true,
          wheels: 2,
          motorSummary: 'DC×2 · L293D 모터쉴드 · 좌/우',
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
          tagline: '메탈 섀시 · 2륜 구동 (DC×2)',
          assetImage: 'assets/kits/metal.png',
          hasLineSensor: false,
          hasUltrasonic: true,
          wheels: 2,
          motorSummary: 'DC×2 · L293D 모터쉴드 · 좌/우',
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
          name: '4휠 스마트 RC카',
          tagline: '4륜 구동 (DC×4) · 강력 주행',
          assetImage: 'assets/kits/four_wheel.jpg',
          hasLineSensor: true,
          hasUltrasonic: true,
          wheels: 4,
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
          assetImage: 'assets/kits/smart_factory.jpg',
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
          assetImage: 'assets/kits/smart_home.jpg',
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
