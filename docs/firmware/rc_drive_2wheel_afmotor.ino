// Author: eduino
// 2휠 투명 RC카 주행 펌웨어 — Adafruit Motor Shield v1 (AFMotor) + HC-06(SoftwareSerial).
// 왼쪽 바퀴 = M1, 오른쪽 바퀴 = M4 (사용자 배선 기준).
// 앱의 라인 프로토콜(DRV/MOV/SPD/STP/PNG)을 받아 모터로 변환한다.
//
// 필요 라이브러리: Adafruit Motor Shield library (AFMotor) — v1 쉴드용.
// HC-06 배선: Arduino A5(RX) ← HC-06 TX,  Arduino A4(TX) → HC-06 RX,  9600bps.

#include <AFMotor.h>
#include <SoftwareSerial.h>

SoftwareSerial bt(A5, A4); // (RX, TX)

AF_DCMotor motorL(1); // 왼쪽 = M1
AF_DCMotor motorR(4); // 오른쪽 = M4

int speedCap = 200;              // 0-255, SPD 명령으로 조절
unsigned long lastCmd = 0;
const unsigned long TIMEOUT = 500; // ms — 통신 끊기면 자동 정지(안전)
String buf = "";

void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  stopAll();
  Serial.println("EDUINO 2WD ready (M1=L, M4=R)");
}

void loop() {
  while (bt.available()) {
    char c = bt.read();
    if (c == '\n') { handle(buf); buf = ""; }
    else if (c != '\r') buf += c;
  }
  if (millis() - lastCmd > TIMEOUT) stopAll(); // 하트비트 끊기면 정지
}

void handle(String line) {
  line.trim();
  if (line.length() == 0) return;
  lastCmd = millis();

  int colon = line.indexOf(':');
  if (colon < 0) return;
  String cmd = line.substring(0, colon);
  String arg = line.substring(colon + 1);

  if (cmd == "DRV") {
    int comma = arg.indexOf(',');
    int th = arg.substring(0, comma).toInt();
    int st = arg.substring(comma + 1).toInt();
    drive(th, st);
  } else if (cmd == "MOV") {
    move(arg);
  } else if (cmd == "SPD") {
    speedCap = map(constrain(arg.toInt(), 0, 100), 0, 100, 0, 255);
  } else if (cmd == "STP") {
    stopAll();
  }
  // PNG(하트비트)는 lastCmd 갱신만으로 충분 — 별도 처리 불필요.
}

// throttle/steer(-100..100) → 좌/우 바퀴 믹싱
void drive(int th, int st) {
  int l = constrain(th + st, -100, 100);
  int r = constrain(th - st, -100, 100);
  runMotor(motorL, l);
  runMotor(motorR, r);
}

void runMotor(AF_DCMotor &m, int val) {
  int pwm = map(abs(val), 0, 100, 0, speedCap);
  m.setSpeed(pwm);
  if (val > 0) m.run(FORWARD);
  else if (val < 0) m.run(BACKWARD);
  else m.run(RELEASE);
}

void move(String d) {
  if (d == "F") drive(80, 0);
  else if (d == "B") drive(-80, 0);
  else if (d == "L") drive(0, -80);   // 제자리 좌회전
  else if (d == "R") drive(0, 80);    // 제자리 우회전
  else if (d == "FL") drive(70, -40);
  else if (d == "FR") drive(70, 40);
  else if (d == "BL") drive(-70, -40);
  else if (d == "BR") drive(-70, 40);
  else stopAll();
}

void stopAll() {
  motorL.run(RELEASE);
  motorR.run(RELEASE);
}
