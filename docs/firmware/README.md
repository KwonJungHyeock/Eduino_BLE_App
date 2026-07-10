# 아두이노 펌웨어

앱은 라인 기반 ASCII 프로토콜(`<CMD>:<args>\n`)만 보낸다. **펌웨어가 이를 하드웨어 동작으로 변환**한다.
용도에 맞는 스케치를 보드에 업로드하세요.

| 파일 | 용도 | 비고 |
|---|---|---|
| `eduino_all_in_one.ino` | **통합 데모** (주행·LED·기울기·음성·자율주행·텔레메트리) | 시연은 대부분 이 스케치 하나로. AFMotor M1=좌/M4=우 |
| `serial_chat.ino` | **시리얼 통신 채팅** 실습 | 앱 ↔ 아두이노 ↔ PC 시리얼 모니터 문자 중계 |
| `rc_drive_2wheel_afmotor.ino` | 2휠 주행만 (최소 예제) | 주행 기능만 볼 때 |

> **담당자 시연은 [`../DEMO.md`](../DEMO.md) 순서대로** 진행하세요. 채팅은 `serial_chat.ino`, 나머지 전부는 `eduino_all_in_one.ino`.

## 공통 배선 (HC-06, 사용자 기준)
- Arduino **A5 (RX)** ← HC-06 **TX**
- Arduino **A4 (TX)** → HC-06 **RX** (5V→3.3V 분압 권장)
- 통신 속도 **9600bps**
- 코드에서는 `SoftwareSerial bt(A5, A4);` (RX, TX 순서)

> HM-10(BLE)을 쓰는 경우도 배선/보율은 동일하게 SoftwareSerial 로 연결하면 된다.

## 주의
- 주행 스케치는 하트비트(`PNG:`) 타임아웃 500ms 로 통신이 끊기면 자동 정지한다(안전).
- 모터가 반대로 돌면 M1/M4 배선의 극성을 바꾸거나 `runMotor` 의 FORWARD/BACKWARD 를 교체.
- 4휠은 모터가 4개라 좌2·우2를 병렬로 묶거나 채널을 늘려야 한다(추후 앱의 모터 포트 설정과 연동 예정).
