// Author: eduino
// 교구 학습 커리큘럼 데이터 — EDUINO 공식 강의자료(v4.1) 원문 순서 그대로.
// 스마트 팜(13 대단원)·스마트 팩토리(8 대단원). 부품·핀 배선·차시·블루투스 명령을
// 자료 기준으로 담는다. 스마트 홈은 원문(텍스트) 확보 후 추가.

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'kit_profile.dart';

/// 핀 종류 — 배선표 색 구분에 사용.
enum PinKind { analog, digital, i2c, bluetooth }

extension PinKindStyle on PinKind {
  Color get color => switch (this) {
        PinKind.analog => AppColors.mint,
        PinKind.digital => AppColors.signal,
        PinKind.i2c => AppColors.sun,
        PinKind.bluetooth => AppColors.accent,
      };
}

class KitPart {
  const KitPart(this.name, this.role, this.color);
  final String name;
  final String role;
  final Color color;
}

class KitWire {
  const KitWire(this.part, this.pin, this.kind);
  final String part;
  final String pin;
  final PinKind kind;
}

class KitLesson {
  const KitLesson(
    this.title,
    this.detail, {
    this.examples = const [],
    this.bluetooth = false,
  });
  final String title;
  final String detail;

  /// 강의자료 예제코드 파일명(있으면 표시).
  final List<String> examples;

  /// 앱 인벤터·블루투스 관련 단원 표시(원격 제어 개념).
  final bool bluetooth;
}

/// 원격 제어(블루투스) 장치 버튼 정의 — 명령 문자는 강의자료 기준.
class KitCommand {
  const KitCommand(this.label, this.command, this.icon, this.color,
      {this.note = ''});
  final String label;
  final String command; // 자료의 실제 전송 문자(예: 'A'/'B', 'r,g,b')
  final IconData icon;
  final Color color;
  final String note;
}

class KitCurriculum {
  const KitCurriculum({
    required this.heroTitle,
    required this.heroDesc,
    required this.heroTags,
    required this.heroColors,
    required this.parts,
    required this.wiring,
    required this.lessons,
    required this.commands,
    required this.btNote,
  });

  final String heroTitle;
  final String heroDesc;
  final List<String> heroTags;
  final List<Color> heroColors; // 그라디언트 2색
  final List<KitPart> parts;
  final List<KitWire> wiring;
  final List<KitLesson> lessons;
  final List<KitCommand> commands;
  final String btNote;

  int get bluetoothUnitCount => lessons.where((l) => l.bluetooth).length;
}

KitCurriculum? kitCurriculumFor(KitType t) => switch (t) {
      KitType.smartFarm => _farm,
      KitType.smartFactory => _factory,
      _ => null,
    };

// ─────────────────────────────────────────────────────────────
// 🌱 스마트 팜 — 강의자료 13 대단원(블루투스/앱은 대단원 9~13, 맨 끝)
// ─────────────────────────────────────────────────────────────
const _farm = KitCurriculum(
  heroTitle: '스마트 온실 만들기',
  heroDesc: '온도·습도·토양수분을 센서로 재고, 팬·RGB 조명·LCD를 자동 제어해요. '
      '강낭콩을 직접 키우며 데이터로 환경을 조절합니다.',
  heroTags: ['DHT11', '토양수분', '네오픽셀', 'LCD', '쿨링팬'],
  heroColors: [Color(0xFF25D3B0), Color(0xFF0FB89A)],
  parts: [
    KitPart('온·습도 센서 (DHT11)', '대기 온도·습도 측정', AppColors.signal),
    KitPart('토양수분 감지 모듈', '흙 속 수분량 측정', AppColors.mint),
    KitPart('네오픽셀 RGB LED', '상태 표시·채광 조명', AppColors.accent),
    KitPart('LCD 1602 (I2C)', '측정값·경고 문자 표시', AppColors.sun),
    KitPart('쿨링팬 ×2', '고온·과습 시 환기', AppColors.signalDeep),
    KitPart('HC-06 블루투스', '스마트폰 앱과 통신', AppColors.accent),
  ],
  wiring: [
    KitWire('온·습도 (DHT11)', 'A0', PinKind.analog),
    KitWire('토양수분', 'A1', PinKind.analog),
    KitWire('네오픽셀 RGB', 'D9', PinKind.digital),
    KitWire('LCD (I2C)', 'A4·A5', PinKind.i2c),
    KitWire('쿨링팬 A·B', 'D4~D7', PinKind.digital),
    KitWire('블루투스 HC-06', 'D2·D3', PinKind.bluetooth),
  ],
  lessons: [
    KitLesson('스마트 팜 이해하기',
        '스마트 온실 개념 · 구성 3파트(센서·제어·운영) · 등장 배경 조사'),
    KitLesson('센서 실습 ① 쉴드·쿨링팬', '센서 확장 쉴드 · 쿨링팬 PWM 속도 제어',
        examples: ['1_CoolingFan', '1-1_CoolingFan_pwm']),
    KitLesson('센서 실습 ② 온습도·토양수분', '측정값 읽고 기준과 비교 · 시리얼 모니터/플로터',
        examples: ['2_DHT11_Module', '3_Soil_Moisture_Module']),
    KitLesson('센서 실습 ③ 네오픽셀·LCD', 'RGB 색상 출력(무지개) · LCD 문자 표시',
        examples: ['4_Neopixel_RGB_LED', '5_LCD_Module']),
    KitLesson('키트 조립하기', '하우징 조립 · 센서 결선 · 강낭콩 흙 화분 준비'),
    KitLesson('활용 · 토양습도 편', '토양습도로 RGB·쿨링팬·LCD 제어',
        examples: ['6_Soilmoisture_RGBLED', '7_Soilmoisture_Coolingfan', '8_Soil_Moisture_LCD']),
    KitLesson('활용 · 온도 편', '온도로 RGB·쿨링팬·LCD 제어',
        examples: ['9_DHT11_RGBLED', '10_DHT11_Fan', '11_DHT_LCD']),
    KitLesson('키트 완성하기', '기준값 4개(최대습도·최대/최저온도·토양수분)로 통합 자동 제어',
        examples: ['12_SmartFarm_KIT']),
    KitLesson('앱 인벤터 기초 ①', '앱 인벤터 입문 · LED 제어 앱 화면 만들기', bluetooth: true),
    KitLesson('앱 인벤터 기초 ② · 블루투스', 'HC-06 원리 · AT 명령(이름/비번) · 앱으로 LED 제어',
        examples: ['13_Bluetooth_Module', '14_Bluetooth_LED_Control'], bluetooth: true),
    KitLesson('앱 제작 ① 토양습도 측정', '토양수분 %를 앱으로 전송·표시',
        examples: ['15_App_Soilmoisture_check'], bluetooth: true),
    KitLesson('앱 제작 ② 온·습도 측정', '온도·습도를 앱으로 전송·표시',
        examples: ['16_App_Temperature_check'], bluetooth: true),
    KitLesson('앱 제작 ③ LED 색상 제어', '앱에서 색상 선택 → RGB 값 전송',
        examples: ['17_App_Neopixel_control'], bluetooth: true),
  ],
  commands: [
    KitCommand('조명 ON', 'A', Icons.lightbulb, AppColors.sun),
    KitCommand('조명 OFF', 'B', Icons.lightbulb_outline, AppColors.textMuted),
    KitCommand('RGB 색상', 'r,g,b', Icons.palette, AppColors.accent,
        note: '빨강·초록·파랑 3바이트 전송'),
  ],
  btNote: '통신: HC-06 블루투스(SPP · 안드로이드 전용). 명령은 라인 규격이 아니라 '
      '단일 문자예요 — 조명 A/B, RGB는 r,g,b 3바이트. 센서값은 텍스트로 앱에 전송됩니다.',
);

// ─────────────────────────────────────────────────────────────
// 🏭 스마트 팩토리 — 강의자료 8 대단원
// (앱/블루투스 "교육"은 대단원 4~5 중간, "최종 앱 제어"는 대단원 8 끝)
// ─────────────────────────────────────────────────────────────
const _factory = KitCurriculum(
  heroTitle: '자동분류 시스템 만들기',
  heroDesc: '컨베이어 벨트 위 물체를 IR로 감지하고, 색상센서로 색을 판별해 '
      '서보모터가 색깔별로 자동 분류하는 스마트 공장을 만들어요.',
  heroTags: ['IR 센서', '색상센서', '서보', '컨베이어', '네오픽셀'],
  heroColors: [Color(0xFF4F97FF), Color(0xFF0A5FD0)],
  parts: [
    KitPart('적외선 IR 센서', '벨트 위 물체 감지', AppColors.sun),
    KitPart('색상센서 (TCS34725)', 'RGB 값으로 색 판별', AppColors.accent),
    KitPart('서보모터 (SG-90)', '색깔별 분류 바 구동', AppColors.signal),
    KitPart('기어드 DC모터', '컨베이어 벨트 구동', AppColors.signalDeep),
    KitPart('네오픽셀 RGB LED', '감지 색상 표시', AppColors.accent),
    KitPart('능동 부저 · HC-06', '알림음 · 앱 제어 통신', AppColors.mint),
  ],
  wiring: [
    KitWire('능동 부저 (내장)', 'D4', PinKind.digital),
    KitWire('서보모터', 'D9', PinKind.digital),
    KitWire('IR 센서', 'A0', PinKind.analog),
    KitWire('색상센서 (I2C)', 'A4·A5', PinKind.i2c),
    KitWire('네오픽셀 RGB', 'D5', PinKind.digital),
    KitWire('DC모터 (벨트)', 'D10~D13', PinKind.digital),
    KitWire('블루투스 HC-06', 'D2·D3', PinKind.bluetooth),
  ],
  lessons: [
    KitLesson('센서 실습 · 쉴드·모터편', 'L298P 쉴드 · 능동 부저 · 기어드 DC모터 속도 제어',
        examples: ['01_L298P_Passive_Buzzer', '02_L298P_Motor_Control', '03_motor_speed_control']),
    KitLesson('센서 실습 · 센서제어편', '적외선 IR 송수신 · 서보모터 각도 제어',
        examples: ['04_irsensor', '05_Servo', '06_IR_servo']),
    KitLesson('센서 실습 · 색상감지편', '색상센서 TCS34725로 RGB 판별 · 네오픽셀 표시',
        examples: ['07_RGBsensor', '08_RGBLED']),
    KitLesson('앱 인벤터 기초 · 블루투스', '앱 인벤터 입문 · HC-06·AT 명령 · 앱으로 LED 제어',
        examples: ['09_BluetoothModule', '10_BT_LED'], bluetooth: true),
    KitLesson('앱 인벤터 기초 ②', '자동분류 전용 앱 UI 제작 · 스마트폰 설치', bluetooth: true),
    KitLesson('자동분류시스템 조립하기', 'MDF 조립 · 센서/블루투스 결합 · 서보 영점 잡기',
        examples: ['00_servo_setting']),
    KitLesson('기능 알아보기', '레일 모터 · 물체 감지 · 색상 감지 단위 통합',
        examples: ['11_DC_Servo', '12_ir_with_motor', '13_Color_LED']),
    KitLesson('완성하기 · 앱 제어', '전 기능 통합 → 앱 블루투스로 가동·정지·분류 결과 제어',
        examples: ['14_conveyer_belt', '15_conveyer_belt_bluetooth'], bluetooth: true),
  ],
  commands: [
    KitCommand('가동', 'RUN', Icons.play_arrow, AppColors.mint),
    KitCommand('정지', 'STOP', Icons.stop, AppColors.accent),
    KitCommand('개수 초기화', 'RESET', Icons.refresh, AppColors.signalDeep),
  ],
  btNote: '서보 분류각: 빨강 2° · 초록 55° · 파랑 30° (강의자료 기준). '
      '시리얼 h=부저 ON, l=OFF. 앱 가동/정지/초기화 명령 문자는 자료에 이미지(앱인벤터 블록)로만 '
      '있어 표시는 임시값이며, 원문 확인 후 확정합니다.',
);
