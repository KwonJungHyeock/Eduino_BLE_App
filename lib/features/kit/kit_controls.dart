// Author: eduino
// 스마트킷 명령/모니터 데이터(데이터 주도) — 명령은 하드코딩 산개 금지, 여기 commandMap 으로 보유.
// 전송 바이트는 HC-06(SPP)/HM-10(BLE) 공용. 화면은 이 데이터로 컨트롤을 자동 렌더.

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'kit_profile.dart';

enum KitCtlKind {
  toggle, // ON/OFF 단일 문자
  colorPreset, // 색상 프리셋 → 단일 문자(홈 RGB)
  colorRgb, // 색상 터치 → R,G,B 3바이트(팜 네오픽셀)
}

/// 색 스와치 — 홈은 char(단일 문자), 팜은 color 의 RGB 3바이트로 전송.
class KitSwatch {
  const KitSwatch(this.label, this.color, {this.char});
  final String label;
  final Color color;
  final String? char; // colorPreset 전용
}

class KitControl {
  const KitControl({
    required this.label,
    required this.kind,
    this.onChar,
    this.offChar,
    this.icon = Icons.power_settings_new,
    this.longPress = false,
    this.swatches = const [],
    this.offSwatchLabel = '끄기',
  });

  final String label;
  final KitCtlKind kind;
  final String? onChar; // toggle ON
  final String? offChar; // toggle OFF / colorPreset·colorRgb 끄기(문자면 char, 팜은 0,0,0)
  final IconData icon;
  final bool longPress; // 오작동 방지(침입자 경보)
  final List<KitSwatch> swatches; // 색상 그리드
  final String offSwatchLabel;
}

enum KitMonKind {
  tempHumi, // "온도,습도" 콤마 텍스트
  soil, // 숫자 또는 숫자% (토양수분)
}

class KitMonitor {
  const KitMonitor(this.label, this.kind, this.icon);
  final String label;
  final KitMonKind kind;
  final IconData icon;
}

class KitControlSet {
  const KitControlSet({
    required this.controls,
    this.monitors = const [],
    this.initChar, // 연결 직후 자동 전송(팩토리 's')
    this.monitorRequest, // 주기 요청 바이트(홈 온습도 0x00)
  });
  final List<KitControl> controls;
  final List<KitMonitor> monitors;
  final String? initChar;
  final List<int>? monitorRequest;
}

// ── 홈 RGB 8색 프리셋(단일 문자) ──
const List<KitSwatch> _homeRgb = [
  KitSwatch('빨강', Color(0xFFE53935), char: 'r'),
  KitSwatch('주황', Color(0xFFFB8C00), char: 'o'),
  KitSwatch('노랑', Color(0xFFFDD835), char: 'y'),
  KitSwatch('초록', Color(0xFF43A047), char: 'g'),
  KitSwatch('파랑', Color(0xFF1E88E5), char: 'b'),
  KitSwatch('보라', Color(0xFF8E24AA), char: 'v'),
  KitSwatch('흰색', Color(0xFFFFFFFF), char: 'w'),
];

// ── 팜 네오픽셀 색(3바이트 RGB) ──
const List<KitSwatch> _farmRgb = [
  KitSwatch('빨강', Color(0xFFFF0000)),
  KitSwatch('주황', Color(0xFFFF8000)),
  KitSwatch('노랑', Color(0xFFFFFF00)),
  KitSwatch('초록', Color(0xFF00FF00)),
  KitSwatch('청록', Color(0xFF00FFFF)),
  KitSwatch('파랑', Color(0xFF0000FF)),
  KitSwatch('보라', Color(0xFF8000FF)),
  KitSwatch('흰색', Color(0xFFFFFFFF)),
];

KitControlSet? kitControlsFor(KitType t) => switch (t) {
      KitType.smartFactory => _factory,
      KitType.smartHome => _home,
      KitType.smartFarm => _farm,
      _ => null, // RC 등은 별도 컨트롤러
    };

// 1. 스마트 팩토리 — 가동/중지 단일 토글. 연결 직후 's' 초기화.
const _factory = KitControlSet(
  initChar: 's',
  controls: [
    KitControl(
      label: '컨베이어 가동 / 중지',
      kind: KitCtlKind.toggle,
      onChar: '1',
      offChar: '0',
      icon: Icons.view_stream,
    ),
  ],
);

// 2. 스마트 홈 — 에어컨·도어 토글, RGB 프리셋, 침입자 경보(길게). 온습도 요청(0x00).
const _home = KitControlSet(
  monitorRequest: [0x00],
  monitors: [
    KitMonitor('온·습도', KitMonKind.tempHumi, Icons.thermostat),
  ],
  controls: [
    KitControl(
      label: '에어컨',
      kind: KitCtlKind.toggle,
      onChar: 'p',
      offChar: 'q',
      icon: Icons.ac_unit,
    ),
    KitControl(
      label: '현관문',
      kind: KitCtlKind.toggle,
      onChar: 'm',
      offChar: 'n',
      icon: Icons.meeting_room,
    ),
    KitControl(
      label: 'RGB 조명',
      kind: KitCtlKind.colorPreset,
      swatches: _homeRgb,
      offChar: 'x',
      icon: Icons.lightbulb,
    ),
    KitControl(
      label: '침입자 경보',
      kind: KitCtlKind.toggle,
      onChar: '1',
      offChar: '0',
      icon: Icons.notifications_active,
      longPress: true, // 오작동 방지
    ),
  ],
);

// 3. 스마트 팜 — 통합 제어판: 냉각팬 토글 + 네오픽셀 RGB. 토양·온습도 모니터.
const _farm = KitControlSet(
  monitors: [
    KitMonitor('토양수분', KitMonKind.soil, Icons.grass),
    KitMonitor('온·습도', KitMonKind.tempHumi, Icons.thermostat),
  ],
  controls: [
    KitControl(
      label: '냉각팬',
      kind: KitCtlKind.toggle,
      onChar: 'A',
      offChar: 'B',
      icon: Icons.air,
    ),
    KitControl(
      label: 'LED (네오픽셀)',
      kind: KitCtlKind.colorRgb,
      swatches: _farmRgb,
      icon: Icons.palette,
    ),
  ],
);

/// 토양수분 % → 단계(25/50/75/100).
int soilStage(double pct) {
  if (pct <= 25) return 25;
  if (pct <= 50) return 50;
  if (pct <= 75) return 75;
  return 100;
}

/// 모니터 값 색(디자인 토큰 재사용).
Color monitorColor(KitMonKind k) => switch (k) {
      KitMonKind.tempHumi => AppColors.accent,
      KitMonKind.soil => AppColors.mint,
    };
