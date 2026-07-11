// Author: eduino
// EDUINO RC 통합 데모 펌웨어 (2휠 RC카) — 앱의 모든 주행/제어 명령을 한 스케치로 처리.
//   지원: DRV(조이스틱/기울기) · MOV(방향버튼) · SPD(속도상한) · STP(정지)
//         LED:<pin>,<0/1>(커스텀 핀) · MOD(MANUAL/AUTO/LINE) · PRM(실시간 튜닝) · PNG(하트비트)
//         MOD:AUTO=초음파 장애물 회피 · MOD:LINE=라인트레이싱(ENABLE_LINE=1 필요)
//   텔레메트리: DST(초음파 거리) · LIN(IR 라인센서) 주기 송신 → 자율주행/라인 화면에 표시
//
// 하드웨어: Adafruit Motor Shield v1(AFMotor), 왼쪽=M1 / 오른쪽=M4
// 블루투스(HC-06): Arduino A5(RX) ← HC-06 TX,  A4(TX) → HC-06 RX,  9600bps
// 필요 라이브러리: Adafruit Motor Shield library (AFMotor)
//
// ※ 시리얼 통신 "채팅" 실습은 이 펌웨어가 아니라 serial_chat.ino 를 올려서 진행한다.

#include <AFMotor.h>
#include <SoftwareSerial.h>

// ---- 핀 설정 (배선에 맞게 조정) --------------------------------------------
SoftwareSerial bt(A5, A4);       // (RX, TX)
AF_DCMotor motorL(1);            // 왼쪽 = M1
AF_DCMotor motorR(4);            // 오른쪽 = M4
const int LED_PIN = 13;

#define ENABLE_ULTRASONIC 1      // 초음파 사용(거리 텔레메트리·장애물 회피)
const int TRIG = A0;
const int ECHO = A1;

#define ENABLE_LINE 0            // IR 라인센서 사용(2휠/4휠=1, 메탈=0)
const int IR_L = A2, IR_C = A3, IR_R = 2;

// ---- 상태 -----------------------------------------------------------------
int speedCap = 255;              // 0-255 (SPD 로 조절)
const int MIN_PWM = 70;          // 정지마찰 보정 최소 출력
int mode = 0;                    // 0=수동 · 1=자율(초음파 장애물) · 2=라인트레이싱
int ledPin = LED_PIN;            // LED:<pin>,<0/1> 로 실행 중 변경 가능
int lineSens = 50, obstDist = 20, autoSpeed = 60; // PRM 튜닝 대상
unsigned long lastCmd = 0, lastTele = 0;
const unsigned long TIMEOUT = 500;   // 통신 끊기면 정지(수동)
const unsigned long TELE_EVERY = 200; // 텔레메트리 주기(ms)
String buf = "";

void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  pinMode(ledPin, OUTPUT);
#if ENABLE_ULTRASONIC
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
#endif
  stopAll();
  bt.println("LOG:EDUINO 2WD ready");
}

void loop() {
  while (bt.available()) {
    char c = bt.read();
    if (c == '\n') { handle(buf); buf = ""; }
    else if (c != '\r') buf += c;
  }

  if (mode == 2) {
    runLine();
  } else if (mode == 1) {
    runAuto();
  } else if (millis() - lastCmd > TIMEOUT) {
    stopAll(); // 수동 모드에서 통신 끊기면 정지
  }

  if (millis() - lastTele > TELE_EVERY) {
    lastTele = millis();
    emitTelemetry();
  }
}

// ---- 명령 처리 -------------------------------------------------------------
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
    drive(arg.substring(0, comma).toInt(), arg.substring(comma + 1).toInt());
  } else if (cmd == "MOV") {
    move(arg);
  } else if (cmd == "SPD") {
    speedCap = map(constrain(arg.toInt(), 0, 100), 0, 100, 0, 255);
  } else if (cmd == "LED") {
    // LED:<pin>,<0/1> (커스텀 핀) 또는 LED:<0/1> (기본 핀) 모두 지원.
    int comma = arg.indexOf(',');
    if (comma >= 0) {
      ledPin = arg.substring(0, comma).toInt();
      pinMode(ledPin, OUTPUT);
      digitalWrite(ledPin, arg.substring(comma + 1).toInt() ? HIGH : LOW);
    } else {
      digitalWrite(ledPin, arg.startsWith("1") ? HIGH : LOW);
    }
  } else if (cmd == "STP") {
    stopAll();
  } else if (cmd == "MOD") {
    if (arg == "AUTO") mode = 1;        // 초음파 장애물 회피
    else if (arg == "LINE") mode = 2;   // 라인트레이싱
    else mode = 0;                      // 수동
    if (mode == 0) stopAll();
    bt.print("MOD:"); bt.println(arg);  // 앱에 응답
  } else if (cmd == "PRM") {
    int comma = arg.indexOf(',');
    String key = arg.substring(0, comma);
    int v = arg.substring(comma + 1).toInt();
    if (key == "LINE") lineSens = v;
    else if (key == "DIST") obstDist = v;
    else if (key == "SPD") autoSpeed = v;
  }
  // PNG(하트비트)는 lastCmd 갱신만으로 충분.
}

// ---- 주행 -----------------------------------------------------------------
void drive(int th, int st) {
  int l = constrain(th + st, -100, 100);
  int r = constrain(th - st, -100, 100);
  runMotor(motorL, l);
  runMotor(motorR, r);
}

void runMotor(AF_DCMotor &m, int val) {
  int pwm = map(abs(val), 0, 100, 0, speedCap);
  if (pwm > 0 && pwm < MIN_PWM) pwm = MIN_PWM;
  m.setSpeed(pwm);
  if (val > 0) m.run(FORWARD);
  else if (val < 0) m.run(BACKWARD);
  else m.run(RELEASE);
}

void move(String d) {
  if (d == "F") drive(80, 0);
  else if (d == "B") drive(-80, 0);
  else if (d == "L") drive(0, -80);
  else if (d == "R") drive(0, 80);
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

// ---- 자율주행 (초음파 장애물 회피) -----------------------------------------
void runAuto() {
#if ENABLE_ULTRASONIC
  long d = readDistanceCm();
  if (d > 0 && d <= obstDist) {
    // 장애물 → 후진 살짝 + 우회전
    drive(-50, 0); delay(150);
    drive(0, 80);  delay(250);
  } else {
    drive(autoSpeed, 0);
  }
#endif
}

// ---- 라인트레이싱 (IR 라인센서) --------------------------------------------
// 2휠: IR_L, IR_R 사용 / 4휠: IR_L, IR_C, IR_R 사용. 검은 선 = 낮은 값 가정.
void runLine() {
#if ENABLE_LINE
  int th = map(autoSpeed, 0, 100, 40, 90);   // 주행 속도
  int thr = map(lineSens, 0, 100, 200, 800); // 민감도 → 검정 판정 임계
  bool onL = analogRead(IR_L) < thr;
  bool onR = analogRead(IR_R) < thr;
  bool onC = analogRead(IR_C) < thr;         // 4휠(중앙) — 2휠이면 무시됨
  if (onC || (onL && onR)) drive(th, 0);     // 중앙/직진
  else if (onL) drive(th, -60);              // 왼쪽으로 보정
  else if (onR) drive(th, 60);               // 오른쪽으로 보정
  else drive(th, 0);                         // 선 놓침 → 직진 유지
#else
  stopAll();
#endif
}

// ---- 텔레메트리 ------------------------------------------------------------
void emitTelemetry() {
#if ENABLE_ULTRASONIC
  long d = readDistanceCm();
  if (d > 0) { bt.print("DST:"); bt.println(d); }
#endif
#if ENABLE_LINE
  bt.print("LIN:");
  bt.print(analogRead(IR_L)); bt.print(',');
  bt.print(analogRead(IR_C)); bt.print(',');
  bt.println(analogRead(IR_R));
#endif
}

#if ENABLE_ULTRASONIC
long readDistanceCm() {
  digitalWrite(TRIG, LOW); delayMicroseconds(2);
  digitalWrite(TRIG, HIGH); delayMicroseconds(10); digitalWrite(TRIG, LOW);
  long dur = pulseIn(ECHO, HIGH, 30000); // ~5m 타임아웃
  if (dur == 0) return -1;
  return dur / 58;
}
#endif
