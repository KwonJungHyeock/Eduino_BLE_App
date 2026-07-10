# EDUINO RC카 블루투스 컨트롤러 앱 — 작업지침서 (v2)

> Claude Code 작업용 프로젝트 스펙 문서
> 컨셉: **Neo Cockpit** (다크 조종석) · 프레임워크: **Flutter (단일 코드베이스, iOS/Android)**
> 대상 제품: 2휠 RC카(H-10) · 메탈 RC카 · 4휠 스마트카
> 블루투스: HM-10(BLE, 주력·크로스플랫폼) · HC-06(Classic SPP, 안드로이드 전용)
>
> **v2 변경점**: 플랫폼을 Flutter로 확정 / **차별화 전략(자율주행 연동)을 핵심 기능으로 격상** / 관련 프로토콜·화면·로드맵 반영.

---

## 0. 이 문서의 사용법

Claude Code가 앱을 처음부터 구축할 때 참조하는 **단일 기준 스펙**입니다. 프로젝트 루트에 `CLAUDE.md`로 배치하거나 `docs/spec.md`로 두고 참조시키세요. 통신 계층(§2·§4)이 완성되기 전에는 어떤 화면 기능도 동작하지 않으므로 **통신 계층을 먼저 확정**합니다.

---

## 1. 프로젝트 개요 & 차별화 전략

### 1.1 목표
아두이노 기반 EDUINO 자율주행 RC카 3종을 스마트폰으로 제어하는 **교육용 블루투스 컨트롤러 앱**. 단순 조종을 넘어, **학생이 자율주행을 직접 실험하고 통신·제어 원리를 학습**하는 것이 목적.

### 1.2 차별화 전략 — 기존 BT 앱과 무엇이 다른가

기존 앱(Dabble, Arduino Bluetooth RC Car, 시리얼 터미널류)은 전부 **범용**이다: 제품과 무관하고, 교육 맥락이 없고, 디자인이 조악하고, 광고가 많다. EDUINO의 무기는 **제품을 직접 소유**하고 **교육이 본업**이라는 점이다. 여기서 차별점이 나온다.

**A. 자율주행 연동 — 핵심 차별점 (헤드라인)**
제품명이 "자율주행 프로젝트"인데 범용 앱은 죄다 수동 조종만 한다. 여기를 판다.
- 앱에서 **수동 ↔ 자율주행 모드 전환** (버튼 하나)
- **실시간 파라미터 튜닝**: 라인트레이싱 민감도, 장애물 회피 거리 임계값, 주행 속도를 폰 슬라이더로 조정 → 코드 재업로드 없이 즉시 반영. "값을 바꿔가며 결과를 관찰"하는 실험 도구가 된다.
- **센서 텔레메트리 시각화**: 초음파 거리, IR 라인센서 상태를 실시간 표시. RC카가 "데이터를 뿜는 학습 도구"가 된다.
- 슬로건 후보: **"조종하는 앱이 아니라, 자율주행을 실험하는 앱."**

**B. 교육 브릿지**
- **"보이는 통신"**: 오가는 명령을 실시간으로 보여주고 각 명령의 동작을 학습 (§4의 ASCII 프로토콜이 그대로 교보재)
- **명령 ↔ 아두이노 코드 매핑**: "지금 이 동작 = 아두이노에서 이 코드 실행 중" 표시 → 코딩 교육 본업과 직결
- eduino.kr **차시·조립 가이드 QR/링크 연동**

**C. 제품 특화**
- **내 키트 선택**(2휠/메탈/4휠) → 딱 맞는 컨트롤 레이아웃·핀 가이드·정품 펌웨어 제공
- **하드웨어 인지**: 메탈 RC카는 IR 라인센서가 없으므로 라인트레이싱 자율주행/텔레메트리를 자동 비활성화. 2휠·4휠은 활성. → "제품을 아는 앱"의 구체적 증거
- 광고 없음, 공식 지원

**D. 미션 / 게이미피케이션**
- 장애물 코스 랩타임, 라인트레이싱 챌린지, 미션 클리어 기록 → 수업 몰입도

**E. 완성도**
- Neo Cockpit 디자인 + 안전장치(자동 정지) + 다중 제어모드 통합. 무료 앱들은 대개 이 중 한둘만 된다.

### 1.3 기능 범위
| 구분 | 기능 | 비고 |
|---|---|---|
| 기존 | 연결/스캔, AT 커맨드·터미널 실습 | 통신 원리 학습 |
| 기존 | 기본 컨트롤러(방향 버튼) | 8방향 + 정지 + 속도 |
| 신규 | 조이스틱 제어 | 아날로그 벡터 → 좌/우 믹싱 |
| 신규 | 기울기(틸트) 제어 | 가속도계 → 조향 |
| 신규 | LED 제어 | ON/OFF 또는 RGB |
| 신규 | 음성 제어 | 온디바이스 STT → 명령 |
| **차별 A** | **자율주행 모드 + 실시간 파라미터 튜닝 + 센서 텔레메트리** | 핵심 |
| **차별 B** | **명령↔코드 매핑, 차시 연동** | 교육 |
| **차별 C** | **키트 선택 기반 맞춤 UI/펌웨어** | 제품 특화 |
| **차별 D** | **미션·챌린지·기록** | 몰입 |

### 1.4 지원 플랫폼
- **Android**: HM-10(BLE) + HC-06(Classic SPP) 모두 지원
- **iOS**: HM-10(BLE)**만** 지원 (§2 참조)

---

## 2. ⚠️ 블루투스 아키텍처 — 반드시 먼저 읽을 것

### 2.1 HC-06 은 iOS에서 원천적으로 불가
- HC-06 = **Bluetooth Classic(SPP)**. iOS는 MFi 미인증 서드파티 앱의 Classic SPP를 차단.
- 따라서 **HC-06 지원은 안드로이드 전용 기능**으로 분리. iOS 빌드에서는 HC-06 UI를 노출하지 않는다.

### 2.2 HM-10 은 크로스플랫폼 (BLE) — 주력
- HM-10 = **BLE**, Android/iOS 모두 동작. **이 앱의 주력 통신 방식.**
- 표준 GATT:
  - Service UUID: `0000FFE0-0000-1000-8000-00805F9B34FB`
  - Characteristic UUID: `0000FFE1-0000-1000-8000-00805F9B34FB` (Write + Notify)
  - **BLE 1회 write 20바이트 제한** 유의(긴 명령 분할). Notify 수신도 조각날 수 있어 `\n` 기준 재조립 필수.

### 2.3 추상화 전략
상위 화면이 통신 방식을 몰라도 되도록 인터페이스로 추상화한다.
```
abstract class BtTransport {
  Stream<BtDevice> scan();
  Future<void> connect(BtDevice device);
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
  Stream<List<int>> get incoming;
  BtConnectionState get state;
}
class BleTransport implements BtTransport { ... }  // HM-10, flutter_blue_plus
class SppTransport implements BtTransport { ... }  // HC-06, flutter_bluetooth_serial (Android only)
```
화면은 `BtTransport`만 알고, 사용자가 고른 모듈에 따라 구현을 주입(DI)한다.

---

## 3. 기술 스택 & 프로젝트 구조

### 3.1 패키지
| 용도 | 패키지 | 비고 |
|---|---|---|
| BLE (HM-10) | `flutter_blue_plus` | 크로스플랫폼 |
| Classic SPP (HC-06) | `flutter_bluetooth_serial` | **Android 전용**, iOS 조건부 제외 |
| 상태관리 | `flutter_riverpod` | 연결·텔레메트리 전역 |
| 조이스틱 | `flutter_joystick` | 또는 커스텀 |
| 기울기 | `sensors_plus` | 가속도계 |
| 음성 | `speech_to_text` | 온디바이스 STT(ko-KR) |
| 권한 | `permission_handler` | BT/마이크/위치 |
| 차트/게이지 | `fl_chart` 등 | 텔레메트리 시각화 |
| 로컬 저장 | `shared_preferences` / `hive` | 키트 선택·미션 기록 |
| QR | `mobile_scanner` | 차시 연동(선택) |

### 3.2 폴더 구조
```
lib/
├── main.dart
├── app/            # theme.dart(Neo Cockpit 토큰), router.dart
├── core/
│   ├── protocol/   # commands.dart, telemetry.dart
│   └── bt/         # bt_transport.dart, ble_transport.dart, spp_transport.dart
├── features/
│   ├── kit/        # 키트 선택·프로파일 (차별 C)
│   ├── connect/    # 스캔·연결
│   ├── terminal/   # AT·시리얼 터미널
│   ├── controller/ # 방향 버튼
│   ├── joystick/   # 조이스틱 (Neo Cockpit 메인)
│   ├── tilt/       # 기울기
│   ├── led/        # LED
│   ├── voice/      # 음성
│   ├── autonomous/ # 자율주행 모드·파라미터 튜닝·텔레메트리 (차별 A)
│   ├── learn/      # 명령↔코드 매핑, 차시 연동 (차별 B)
│   └── missions/   # 미션·챌린지·기록 (차별 D)
├── widgets/        # 게이지, 상태바, 센서 표시 등 공용
└── providers/      # Riverpod providers
```

### 3.3 플랫폼 설정 체크리스트
- **iOS Info.plist**: `NSBluetoothAlwaysUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`
- **Android Manifest**: `BLUETOOTH_SCAN`·`BLUETOOTH_CONNECT`(12+, `neverForLocation` 검토), `ACCESS_FINE_LOCATION`(11↓ 스캔), `RECORD_AUDIO`. HC-06 코드는 `Platform.isAndroid` 가드로만 진입.

---

## 4. 통신 프로토콜 (App ↔ Arduino)

앱·펌웨어를 모두 EDUINO가 통제하므로 **사람이 읽는 라인 기반 ASCII 프로토콜**로 정의한다(교육 효과 = "보이는 통신").

### 4.1 프레임 형식
```
<CMD>:<arg1>,<arg2>,...\n
```
대문자 3글자 + 콜론 + 콤마 인자 + 개행. BLE 20바이트 고려해 짧게 유지.

### 4.2 App → Car (명령)
| 명령 | 형식 | 설명 |
|---|---|---|
| 드라이브/조이스틱 | `DRV:<throttle>,<steer>` | -100..100, 펌웨어가 좌/우 PWM 믹싱 |
| 방향 버튼 | `MOV:<dir>` | `F/B/L/R/FL/FR/BL/BR/S` |
| 속도 상한 | `SPD:<0-100>` | 최대 속도 캡(%) |
| 정지 | `STP:` | 즉시 정지(안전) |
| LED | `LED:<0/1>` 또는 `LED:<r>,<g>,<b>` | ON/OFF 또는 RGB |
| **주행 모드** | `MOD:AUTO` / `MOD:MANUAL` | **자율↔수동 전환 (차별 A)** |
| **파라미터 튜닝** | `PRM:<key>,<val>` | **key=`LINE`(민감도0-100)/`DIST`(장애물 임계 cm)/`SPD`(자율속도0-100) (차별 A)** |
| 하트비트 | `PNG:` | 주기 전송, 미수신 시 자동 정지 |
| AT 패스스루 | `RAW:<text>` | 터미널 원문 전송 |

### 4.3 Car → App (텔레메트리)
| 키 | 형식 | 설명 |
|---|---|---|
| 거리 | `DST:<cm>` | 초음파 |
| **라인센서** | `LIN:<l>,<c>,<r>` | **IR 3채널 (0/1 또는 아날로그) (차별 A)** |
| 모드 | `MOD:<AUTO/MANUAL>` | 현재 모드 응답 |
| 배터리 | `BAT:<pct>` | 전압 분압 시 |
| 응답 | `ACK:<cmd>` | 수신 확인 |
| 로그 | `LOG:<text>` | 터미널 표시용 |

### 4.4 설계 원칙
- **안전 우선**: 연결 끊김/백그라운드 시 즉시 `STP:`. 펌웨어는 하트비트 타임아웃(예 500ms) 자동 정지.
- **송신 스로틀링**: 조이스틱·틸트·PRM 슬라이더는 초당 10~20회로 제한.
- **레거시 호환(선택)**: 기존 HC-06 예제의 단일문자(`F/B/L/R/S`) 호환이 필요하면 펌웨어에 레거시 파서 병행.

---

## 5. 화면 구조 & 기능 명세 (Neo Cockpit)

### 5.1 전체 흐름
```
[스플래시]
   ↓
[키트 선택]  (최초 1회, 이후 변경 가능) — 2휠 / 메탈 / 4휠
   ↓  → 선택 결과가 사용 가능한 모드·레이아웃·핀가이드·펌웨어를 결정
[연결 화면]  모듈 선택(HM-10 BLE / HC-06 SPP*) → 스캔 → 연결
   ↓
[메인 허브]  하단 탭으로 모드 전환
   ├─ 조이스틱 (기본)
   ├─ 방향 버튼
   ├─ 기울기
   ├─ LED
   ├─ 음성
   ├─ 자율주행 · 실험      ★ 차별 A
   ├─ 미션                ★ 차별 D
   └─ 터미널 / AT
(* HC-06 탭은 iOS에서 숨김 / 라인트레이싱 관련은 메탈 RC카에서 숨김)
```

### 5.2 조이스틱 모드 (Neo Cockpit 메인)
가로 모드. 상단 상태바(모듈·기기명·연결색·배터리·거리), 중앙 대형 속도 텔레메트리, 하단 좌 가상 조이스틱, 하단 우 속도 상한 슬라이더+정지, 하단 바로가기(LED·기울기·음성·터미널).

### 5.3 방향 버튼 모드
D-패드(8방향)+중앙 정지(빨강). press/release로 `MOV:` 전송. 속도 상한 공유.

### 5.4 기울기 모드
가속도계 → x=조향, y=throttle. 데드존/민감도 슬라이더, "수평=정지" 캘리브레이션, 수평계 UI. 안전 정지 옵션.

### 5.5 LED 제어
단색: ON/OFF + 점멸 프리셋. RGB(네오픽셀): 컬러 휠 → `LED:r,g,b`.

### 5.6 음성 제어
`speech_to_text` ko-KR. 키워드 매핑(전진→`MOV:F`, 정지→`STP:`, "불 켜"→`LED:1` 등). 인식 텍스트·매핑 결과 표시, 무음 타임아웃 후 자동 재시작 옵션.

### 5.7 자율주행 · 실험 모드 ★ 차별 A
- 상단: **수동/자율 토글** (`MOD:` 전송)
- 자율 모드일 때 표시:
  - **라이브 텔레메트리**: 초음파 거리 게이지, IR 라인센서 3채널 상태(3-LED 시각화)
  - **파라미터 슬라이더**: 라인 민감도 / 장애물 임계거리 / 자율 속도 → 조정 즉시 `PRM:` 전송, 코드 재업로드 없이 반영
- 교육 흐름 강조: "값을 바꾸면 → 로봇 행동이 바뀐다"를 눈으로 확인
- **메탈 RC카에서는 라인 관련 요소 자동 숨김**(IR 미탑재), 장애물 회피만 노출

### 5.8 미션 모드 ★ 차별 D
- 챌린지 목록: 장애물 코스 랩타임, 라인트레이싱 완주, 특정 미션
- 랩타임 측정·기록 저장(로컬), 개인 베스트

### 5.9 터미널 / AT 커맨드 + 코드 매핑 ★ 차별 B
- 송/수신 로그(송신=회색, 수신=녹색), 입력창→`RAW:` 전송, HEX/ASCII 토글, 클리어/공유
- HM-10 AT 예제 버튼(`AT`, `AT+NAME?`, `AT+ROLE?`, `AT+RESET`)
  - ⚠️ HM-10/HC-06 은 **미연결(AT 모드)**에서만 AT에 응답. 연결 후 데이터채널로 보낸 AT는 아두이노로 전달될 뿐 모듈 설정은 안 바뀜 → 이 원리를 화면 안내로 교육 포인트화.
- **"코드 보기" 토글**: 현재 조작에 대응하는 아두이노 코드 스니펫 표시("이 동작 = 이 코드"). eduino.kr 차시 링크/QR.

---

## 6. 디자인 시스템 — Neo Cockpit

### 6.1 컬러 (다크)
| 역할 | 값 |
|---|---|
| Base BG | `#12151C` |
| Surface | `#171B24` |
| Border | `#2A3140` |
| Accent(브랜드) | `#E31E24` (EDUINO 레드, 정지/강조) |
| Signal | `#7CE0C3` (연결/텔레메트리 정상) |
| Text Primary | `#E8ECF2` |
| Text Muted | `#5B6472` |
| Warn | `#F5A524` |

### 6.2 타이포
수치·텔레메트리·터미널 = **JetBrains Mono** / 본문·라벨 = **Pretendard**. 대형 수치는 굵기 대비로 계기판 느낌.

### 6.3 원칙
계기판/조종석 은유(네온 글로우는 절제, 색 대비로 표현). 터치 영역 48dp+. 컨트롤러는 가로 우선, 나머지는 세로 대응.

### 6.4 완성도 & "AI로 찍어낸 느낌" 배제 원칙 ★

이 앱의 디자인 목표는 **고급스러움과 높은 완성도**다. 완성도는 장식이 아니라 **정밀함·일관성·의도**에서 나온다. 아래를 강제 규칙으로 따른다.

**금지 — "AI로 찍어낸 도형이미지" 유형**
- 자동 생성한 추상 도형/블롭(blob), 의미 없는 기하학 장식, 그라디언트 메시, 노이즈 텍스처, 떠다니는 원·삼각형 데코 **금지**.
- 빈 공간을 채우기 위한 장식용 일러스트/플레이스홀더 그래픽 **금지**. 모든 시각 요소는 기능적 근거가 있어야 한다.
- 출처·스타일이 제각각인 아이콘 혼용 금지.

**고급스러움을 만드는 방법 (장식이 아니라 크래프트)**
- **여백과 정밀 그리드**: 8pt 그리드, 일관된 간격 리듬, 픽셀 정렬. 여백을 두려워하지 말 것(꽉 채우지 않는다).
- **타이포 위계**로 정보를 조직(§6.2). 텍스트 대비·굵기로 계층을 만들되 색·크기 남발 금지.
- **일관된 아이콘 세트 하나**만 사용(예: Phosphor / Lucide 등 라인 아이콘 한 패밀리)로 톤 통일.
- **의미 있는 데이터 시각화가 곧 히어로 비주얼**: 속도 게이지, 초음파 거리 게이지, 라인센서 상태 표시 등은 **실제 계기(instrument)로 정교하게 제작**한다. 이 "진짜 계기판"이 조종석 컨셉의 고급감을 정당하게 만든다(가짜 장식 도형이 아니라).
- **모션이 완성도를 증명**: 조이스틱 스프링 반응, 게이지 바늘의 부드러운 이징, 연결 상태 전환 애니메이션 등 **절제되고 목적 있는 마이크로 인터랙션**. 과한 연출은 금지.
- **촉각 피드백**: 주요 조작에 햅틱 적용.
- **다크 테마를 제대로**: 밋밋한 회색이 아니라 표면(surface) 단계별 elevation·대비로 깊이를 표현.

**시각 자산 전략 (AI 생성물 대신 실물)**
- 키트 선택·온보딩 화면에는 **EDUINO가 보유한 3종 제품의 실제 제품 사진/렌더**를 사용한다. 자사 제품을 직접 소유한다는 점을 활용 — 이게 범용 앱과의 결정적 차별이자 "AI 도형" 회피의 정답.
- 일러스트가 꼭 필요하면 브랜드 톤에 맞춘 **목적 있는 커스텀 제작물**만 사용.

**Claude Code 적용 지침**
- 데코용 SVG 도형/그라디언트 배경을 만들지 말 것. 화면을 채워야 할 땐 여백·타이포·실제 데이터 컴포넌트로 채운다.
- 게이지·조이스틱·센서 표시는 커스텀 위젯으로 정성껏 구현(대충 만든 원/사각형 금지).
- 제품 이미지는 실제 에셋 슬롯(`assets/kits/`)으로 비워두고, EDUINO가 실사진을 넣도록 구조만 마련한다.

---

## 7. 아두이노 펌웨어 규격

> 앱은 하드웨어를 모른다(프로토콜만 전송). **펌웨어가 프로토콜을 핀 동작으로 변환**한다. 아래 핀맵은 **예시 기본값**이며 실제 키트/쉴드 배선(EDUINO 예제 코드 기준)으로 반드시 재확인.

### 7.1 제품별 구동 구조 (좌/우 2채널로 공통 추상화)
| 제품 | 모터 | 논리 채널 | 특이 |
|---|---|---|---|
| 2휠 RC카 | DC×2 | 좌/우 | L298N, IR 있음 |
| 메탈 RC카 | DC×2 | 좌/우 | L298N, **IR 없음** |
| 4휠 스마트카 | DC×4 | 좌/우(좌2·우2 병렬) | L298N ×2 또는 4채널, IR 있음 |

### 7.2 예시 핀맵 (컨트롤러 펌웨어)
```
BT_RX=2, BT_TX=3         // SoftwareSerial (TX측 5V→3.3V 분배 권장)
ENA=5, IN1=A0, IN2=A1    // 좌
ENB=6, IN3=A2, IN4=A3    // 우
LED_PIN=13
// (자율주행용) 초음파 TRIG/ECHO, IR 라인센서 L/C/R 핀은 기존 자율주행 스케치 기준
```

### 7.3 참조 스켈레치 (핵심 핸들러)
```cpp
// Author: eduino
#include <SoftwareSerial.h>
SoftwareSerial bt(2, 3);

const int ENA=5, IN1=A0, IN2=A1;
const int ENB=6, IN3=A2, IN4=A3;
const int LED_PIN=13;

int speedCap=200;                 // 0-255
bool autoMode=false;              // 자율주행 여부
int  lineSens=50, obstDist=20, autoSpeed=60;  // PRM 튜닝 대상
unsigned long lastCmd=0;
const unsigned long TIMEOUT=500;
String buf="";

void setup(){
  pinMode(ENA,OUTPUT);pinMode(IN1,OUTPUT);pinMode(IN2,OUTPUT);
  pinMode(ENB,OUTPUT);pinMode(IN3,OUTPUT);pinMode(IN4,OUTPUT);
  pinMode(LED_PIN,OUTPUT);
  bt.begin(9600); Serial.begin(9600); stop();
}

void loop(){
  while(bt.available()){
    char c=bt.read();
    if(c=='\n'){ handle(buf); buf=""; }
    else if(c!='\r') buf+=c;
  }
  if(autoMode) runAuto();                 // 자율주행 로직(기존 스케치 이식)
  else if(millis()-lastCmd>TIMEOUT) stop();// 수동 시 통신 끊기면 정지
  // 주기적으로 텔레메트리 송신: emitTelemetry();
}

void handle(String line){
  lastCmd=millis();
  int c=line.indexOf(':'); if(c<0) return;
  String cmd=line.substring(0,c), arg=line.substring(c+1);

  if(cmd=="DRV"){ int k=arg.indexOf(','); drive(arg.substring(0,k).toInt(), arg.substring(k+1).toInt()); }
  else if(cmd=="MOV") move(arg);
  else if(cmd=="SPD") speedCap=map(arg.toInt(),0,100,0,255);
  else if(cmd=="LED") digitalWrite(LED_PIN, arg.startsWith("1")?HIGH:LOW);
  else if(cmd=="STP") stop();
  else if(cmd=="MOD"){ autoMode=(arg=="AUTO"); if(!autoMode) stop(); bt.print("MOD:"); bt.println(autoMode?"AUTO":"MANUAL"); }
  else if(cmd=="PRM"){ int k=arg.indexOf(','); String key=arg.substring(0,k); int v=arg.substring(k+1).toInt();
      if(key=="LINE") lineSens=v; else if(key=="DIST") obstDist=v; else if(key=="SPD") autoSpeed=v; }
}

void emitTelemetry(){
  // bt.print("DST:"); bt.println(readUltrasonic());
  // bt.print("LIN:"); bt.print(irL); bt.print(','); bt.print(irC); bt.print(','); bt.println(irR);
}

void runAuto(){ /* obstDist/lineSens/autoSpeed 를 사용하는 기존 자율주행 로직 */ }

void drive(int th,int st){
  int l=constrain(th+st,-100,100), r=constrain(th-st,-100,100);
  motor(IN1,IN2,ENA,l); motor(IN3,IN4,ENB,r);
}
void motor(int a,int b,int en,int val){
  int pwm=map(abs(val),0,100,0,speedCap);
  digitalWrite(a,val>=0?HIGH:LOW); digitalWrite(b,val>=0?LOW:HIGH); analogWrite(en,pwm);
}
void move(String d){ if(d=="F")drive(80,0);else if(d=="B")drive(-80,0);else if(d=="L")drive(0,-80);else if(d=="R")drive(0,80);else stop(); }
void stop(){ analogWrite(ENA,0); analogWrite(ENB,0); }
```
> 시작점 스케치다. 모터 극성/회전 방향은 조립 후 `IN` 핀 순서로 보정. 자율주행 로직(`runAuto`)과 센서 읽기는 기존 EDUINO 자율주행 스케치를 이식하되, 하드코딩 상수를 `lineSens/obstDist/autoSpeed` 변수로 바꿔 앱 튜닝이 먹히게 한다.

---

## 8. 개발 로드맵

| 단계 | 산출물 | 완료 기준 |
|---|---|---|
| P0 | 스캐폴딩·테마·라우팅 | 화면 흐름 이동 |
| P1 | `BtTransport` + BLE(HM-10) | HM-10 스캔·연결·송수신 |
| P2 | 프로토콜 인코더/디코더 + 터미널 | 명령 송신·수신 로그 확인 |
| P3 | 키트 선택 프로파일 + 방향 버튼 | 키트별 레이아웃, 실제 8방향 주행 |
| P4 | 조이스틱 모드(Neo Cockpit 메인) | 아날로그 주행 + 텔레메트리 |
| P5 | **자율주행·실험 모드** | 모드 전환 + 센서 텔레메트리 + PRM 실시간 튜닝 ★ |
| P6 | LED / 기울기 / 음성 | 부가기능 |
| P7 | 미션 모드 + 코드매핑·차시 연동 | 랩타임 기록, 코드 보기 ★ |
| P8 | HC-06(SPP, Android 전용) | 안드로이드 HC-06 주행 |
| P9 | 안전·스로틀링·에러·폴리싱 | 끊김/백그라운드 자동 정지 검증 |
| P10 | iOS/Android 실기기 + 3종 실주행 QA | 릴리스 후보 |

각 단계는 실기기(또는 HM-10 브레드보드)로 검증 후 진행.

---

## 9. Claude Code 작업 지침 & 미결 사항

### 9.1 CLAUDE.md 규칙
- 코드 헤더 주석 author = `eduino`, 프로젝트명 미표기
- 상태관리 Riverpod, 통신은 반드시 `BtTransport` 경유(화면이 flutter_blue_plus/flutter_bluetooth_serial 직접 import 금지)
- 모든 주행 명령 전송 지점에 **송신 스로틀링 + 연결 상태 가드**
- HC-06 코드는 `if(Platform.isAndroid)` 가드 + iOS 조건부 컴파일
- 키트 프로파일이 **사용 가능한 모드/UI를 결정**(메탈=IR 라인 기능 숨김)
- **디자인 완성도 규칙(§6.4) 준수**: 장식용 SVG 도형·그라디언트·생성형 플레이스홀더 금지, 여백·타이포·실제 데이터 컴포넌트로 화면 구성, 게이지/조이스틱/센서 표시는 커스텀 위젯으로 정성껏, 제품 이미지는 실사진 에셋 슬롯(`assets/kits/`)으로 구조화

### 9.2 버그 주의 지점
- BLE 20바이트 write 제한 → 긴 프레임 분할
- HM-10 notify 조각 도착 → `\n` 재조립 버퍼
- 백그라운드/끊김 즉시 정지
- Android 12+ 권한 런타임 흐름

### 9.3 EDUINO 내부 확정 필요
1. 각 키트 **모터 드라이버 실제 핀 배선** (§7.2 갱신)
2. LED **단색/네오픽셀** 여부
3. 4휠 L298N 구성(1×4ch vs 2개)·핀
4. **자율주행 스케치의 튜닝 상수**를 `LINE/DIST/SPD` 변수로 노출 가능한지(§7.3), 텔레메트리(`DST`/`LIN`) 송신 주기
5. 레거시 단일문자 프로토콜 호환 유지 필요 여부

---

## 10. 요약
- **Flutter 단일 코드베이스**(iOS/Android), HM-10(BLE) 주력 · HC-06(SPP) 안드로이드 전용.
- 앱 하나가 **좌/우 2채널 + 부가기능 + 자율주행 제어** 프로토콜로 3종 제어, 차이는 펌웨어 핀맵·키트 프로파일에서 흡수.
- **핵심 차별점 = 자율주행 연동**: 모드 전환 + 실시간 파라미터 튜닝 + 센서 텔레메트리 → "조종이 아니라 실험하는 앱".
- 교육 브릿지(보이는 통신·코드 매핑·차시 연동), 제품 특화(키트 맞춤), 미션, Neo Cockpit 완성도로 범용 앱과 격차.
- **디자인은 고급감·높은 완성도 지향**: "AI로 찍어낸 도형이미지" 배제, 장식이 아니라 정밀·일관·의도로 완성. 실물 제품 사진과 진짜 계기(게이지·센서) 시각화가 히어로 비주얼(§6.4).
- 안전장치(하트비트·자동 정지)는 처음부터 내장.
