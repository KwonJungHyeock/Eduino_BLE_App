// Author: eduino
// 키트 프로파일 (차별 C, §1.2·§7.1). 선택 결과가 사용 가능한 모드/레이아웃/기능을 결정한다.
// 하드웨어 인지: 메탈 RC카는 IR 라인센서가 없으므로 라인 관련 UI 자동 숨김.

import 'package:flutter/material.dart';

enum KitType { twoWheel, metal, fourWheel }

class KitProfile {
  const KitProfile({
    required this.type,
    required this.name,
    required this.tagline,
    required this.assetImage,
    required this.hasLineSensor,
    required this.hasUltrasonic,
    required this.motorSummary,
  });

  final KitType type;
  final String name;
  final String tagline;

  /// 실사진 에셋 슬롯 경로 (§6.4). 파일이 없으면 UI 가 아이콘 플레이스홀더로 폴백.
  final String assetImage;

  /// IR 라인센서 탑재 여부 — 라인트레이싱 자율/텔레메트리 노출 결정.
  final bool hasLineSensor;

  /// 초음파 거리센서 탑재 여부 — 장애물 회피/거리 게이지 노출 결정.
  final bool hasUltrasonic;

  /// 구동 구조 요약(핀 가이드 표시용).
  final String motorSummary;

  /// 자율주행·실험 모드 사용 가능 여부(센서가 하나라도 있으면 실험 가치 있음).
  bool get supportsAutonomous => hasLineSensor || hasUltrasonic;

  String get storageKey => type.name;

  static KitProfile forType(KitType type) {
    switch (type) {
      case KitType.twoWheel:
        return const KitProfile(
          type: KitType.twoWheel,
          name: '2휠 RC카',
          tagline: 'H-10 · IR 라인센서 + 초음파',
          assetImage: 'assets/kits/two_wheel.png',
          hasLineSensor: true,
          hasUltrasonic: true,
          motorSummary: 'DC×2 · L298N · 좌/우',
        );
      case KitType.metal:
        return const KitProfile(
          type: KitType.metal,
          name: '메탈 RC카',
          tagline: '초음파 장애물 회피 (IR 라인센서 없음)',
          assetImage: 'assets/kits/metal.png',
          hasLineSensor: false, // 라인 관련 기능 자동 숨김 (§5.7)
          hasUltrasonic: true,
          motorSummary: 'DC×2 · L298N · 좌/우',
        );
      case KitType.fourWheel:
        return const KitProfile(
          type: KitType.fourWheel,
          name: '4휠 스마트카',
          tagline: 'IR 라인센서 + 초음파 · 4륜 구동',
          assetImage: 'assets/kits/four_wheel.png',
          hasLineSensor: true,
          hasUltrasonic: true,
          motorSummary: 'DC×4 · L298N×2 · 좌2·우2 병렬',
        );
    }
  }

  static const List<KitType> all = [
    KitType.twoWheel,
    KitType.metal,
    KitType.fourWheel,
  ];

  /// 실사진이 없을 때 카드에 쓰는 라인 아이콘 폴백(한 아이콘 패밀리 유지, §6.4).
  IconData get fallbackIcon {
    switch (type) {
      case KitType.twoWheel:
        return Icons.two_wheeler_outlined;
      case KitType.metal:
        return Icons.directions_car_outlined;
      case KitType.fourWheel:
        return Icons.airport_shuttle_outlined;
    }
  }
}
