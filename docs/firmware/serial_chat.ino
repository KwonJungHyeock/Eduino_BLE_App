// Author: eduino
// 시리얼 통신 채팅 실습 펌웨어 — 앱 ↔ 아두이노 ↔ PC 시리얼 모니터 문자 중계.
// 앱의 "시리얼 통신 채팅" 화면과 짝을 이룬다. (프로토콜 없이 문자열 그대로 주고받음)
// HC-06 배선: Arduino A5(RX) ← HC-06 TX, Arduino A4(TX) → HC-06 RX, 9600bps.

#include <SoftwareSerial.h>

SoftwareSerial bluetooth(A5, A4); // (RX, TX)

void setup() {
  Serial.begin(9600);
  while (!Serial) {
    ; // 시리얼 포트 연결 대기 (우노에서는 생략 가능)
  }
  bluetooth.begin(9600); // HC-05/06 기본 9600
  Serial.println("Bluetooth Serial Communication Ready!");
}

void loop() {
  // 1. 앱 → 아두이노 → PC 시리얼 모니터
  if (bluetooth.available()) {
    String msgFromApp = bluetooth.readStringUntil('\n');
    msgFromApp.trim();
    if (msgFromApp.length() > 0) {
      Serial.print("[App -> Arduino]: ");
      Serial.println(msgFromApp);
    }
  }

  // 2. PC 시리얼 모니터 → 아두이노 → 앱
  if (Serial.available()) {
    String msgFromPC = Serial.readStringUntil('\n');
    msgFromPC.trim();
    if (msgFromPC.length() > 0) {
      bluetooth.println(msgFromPC); // 앱으로 전송
      Serial.print("[Arduino -> App]: ");
      Serial.println(msgFromPC);
    }
  }
}
