// Author: eduino
// 프로토콜 회귀 테스트 — 인코더(Commands)·디코더(TelemetryDecoder)·재조립(LineReassembler).
// "보이는 통신"의 계약이 바뀌면 여기서 먼저 깨진다.

import 'package:flutter_test/flutter_test.dart';

import 'package:eduino_rc/core/protocol/commands.dart';
import 'package:eduino_rc/core/protocol/telemetry.dart';

void main() {
  group('Commands 인코딩', () {
    test('drive 는 범위를 -100..100 로 클램프', () {
      expect(Commands.drive(50, -30), 'DRV:50,-30');
      expect(Commands.drive(200, -200), 'DRV:100,-100');
    });

    test('move 8방향 코드', () {
      expect(Commands.move(MoveDir.f), 'MOV:F');
      expect(Commands.move(MoveDir.br), 'MOV:BR');
      expect(Commands.move(MoveDir.s), 'MOV:S');
    });

    test('speedCap 0..100', () {
      expect(Commands.speedCap(60), 'SPD:60');
      expect(Commands.speedCap(150), 'SPD:100');
      expect(Commands.speedCap(-5), 'SPD:0');
    });

    test('stop / ping', () {
      expect(Commands.stop(), 'STP:');
      expect(Commands.ping(), 'PNG:');
    });

    test('LED 기본/커스텀 핀', () {
      expect(Commands.ledOnOff(true), 'LED:1');
      expect(Commands.ledOnOff(false), 'LED:0');
      expect(Commands.led(13, true), 'LED:13,1');
      expect(Commands.led(7, false), 'LED:7,0');
    });

    test('mode 3종', () {
      expect(Commands.mode(DriveMode.manual), 'MOD:MANUAL');
      expect(Commands.mode(DriveMode.auto), 'MOD:AUTO');
      expect(Commands.mode(DriveMode.line), 'MOD:LINE');
    });

    test('param / servo / actuator / lcd', () {
      expect(Commands.param(PrmKey.line, 40), 'PRM:LINE,40');
      expect(Commands.servo(0, 200), 'SRV:0,180');
      expect(Commands.actuator(1, true), 'ACT:1,1');
      expect(Commands.actuatorPwm(0, 250), 'ACT:0,100');
      expect(Commands.lcd(0, '안녕'), 'LCD:0,안녕');
    });

    test('encode 는 개행을 한 번만 붙인다', () {
      expect(Commands.encode('STP:'), 'STP:\n'.codeUnits);
      expect(Commands.encode('STP:\n'), 'STP:\n'.codeUnits);
    });
  });

  group('TelemetryDecoder 디코딩', () {
    test('DST', () {
      expect(TelemetryDecoder.decode('DST:30'),
          isA<DistanceEvent>().having((e) => e.cm, 'cm', 30));
    });

    test('LIN 3채널', () {
      final e = TelemetryDecoder.decode('LIN:1,0,1');
      expect(e, isA<LineSensorEvent>());
      e as LineSensorEvent;
      expect([e.left, e.center, e.right], [1, 0, 1]);
    });

    test('MOD AUTO/LINE/MANUAL', () {
      expect((TelemetryDecoder.decode('MOD:AUTO') as ModeEvent).mode,
          DriveMode.auto);
      expect((TelemetryDecoder.decode('MOD:LINE') as ModeEvent).mode,
          DriveMode.line);
      expect((TelemetryDecoder.decode('MOD:MANUAL') as ModeEvent).mode,
          DriveMode.manual);
    });

    test('SEN 키/값', () {
      final e = TelemetryDecoder.decode('SEN:TMP,24.5') as SensorEvent;
      expect(e.key, 'TMP');
      expect(e.value, 24.5);
    });

    test('BAT / ACK', () {
      expect((TelemetryDecoder.decode('BAT:80') as BatteryEvent).percent, 80);
      expect((TelemetryDecoder.decode('ACK:DRV') as AckEvent).cmd, 'DRV');
    });

    test('형식 오류는 UnknownEvent 로 보존', () {
      expect(TelemetryDecoder.decode('garbage'), isA<UnknownEvent>());
      expect(TelemetryDecoder.decode('DST:abc'), isA<UnknownEvent>());
    });
  });

  group('LineReassembler 재조립', () {
    test('개행 기준으로 완성 라인만 방출', () {
      final r = LineReassembler();
      final out = <String>[];
      out.addAll(r.add('DST:12\nDST'.codeUnits));
      out.addAll(r.add(':34\n'.codeUnits));
      expect(out, ['DST:12', 'DST:34']);
    });

    test('CR 은 무시', () {
      final r = LineReassembler();
      expect(r.add('MOD:AUTO\r\n'.codeUnits).toList(), ['MOD:AUTO']);
    });
  });
}
