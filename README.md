# EDUINO RC카 블루투스 컨트롤러 (Neo Cockpit)

EDUINO 자율주행 RC카 3종(2휠·메탈·4휠)을 스마트폰으로 제어하는 **교육용 블루투스 컨트롤러 앱**.
단순 조종을 넘어 **자율주행을 직접 실험**하는 도구가 핵심 차별점이다.

> 작업 기준 스펙: [`docs/spec.md`](docs/spec.md) · 코드 규칙 요약: [`CLAUDE.md`](CLAUDE.md)

## 현재 구현 범위 (P0–P5)

| 단계 | 산출물 | 상태 |
|---|---|---|
| P0 | 스캐폴딩 · Neo Cockpit 테마 · 라우팅 | ✅ |
| P1 | `BtTransport` 추상화 + BLE(HM-10) 전송 | ✅ |
| P2 | 프로토콜 인코더/디코더 + 터미널("보이는 통신") | ✅ |
| P3 | 키트 선택 프로파일 + 방향 버튼(8방향) | ✅ |
| P4 | 조이스틱 모드(Neo Cockpit 메인) + 속도 게이지 | ✅ |
| P5 | **자율주행·실험 모드**(모드 전환·센서 텔레메트리·PRM 실시간 튜닝) ★ | ✅ |

후속(P6–P10): LED · 기울기 · 음성 · 미션 · 코드매핑 · HC-06(SPP) · 폴리싱.

## 아키텍처

```
lib/
├── main.dart              # 진입점 + 백그라운드 안전 정지(STP)
├── app/
│   ├── theme.dart         # Neo Cockpit 디자인 토큰(§6.1/6.2)
│   └── router.dart        # go_router 흐름(§5.1)
├── core/
│   ├── protocol/
│   │   ├── commands.dart  # App→Car 인코더(§4.2)
│   │   └── telemetry.dart # Car→App 디코더 + \n 재조립(§4.3/§9.2)
│   └── bt/
│       ├── bt_transport.dart   # 통신 추상 인터페이스(화면이 아는 유일한 계약)
│       └── ble_transport.dart  # HM-10 구현(flutter_blue_plus 캡슐화 · 20B 분할)
├── features/              # splash · kit · connect · hub · controller · joystick · autonomous · terminal
├── widgets/               # 커스텀 계기: 조이스틱 · 속도/거리 게이지 · IR 라인센서 · 상태바
└── providers/             # Riverpod: 연결·텔레메트리·터미널·키트·CarController
```

**강제 규칙**
- 통신은 반드시 `BtTransport` 경유 — 화면/위젯은 `flutter_blue_plus` 를 직접 import 하지 않는다.
- 모든 주행 명령은 `CarController` 한 곳에서만 전송 — **송신 스로틀링 + 연결 가드 + 하트비트(PNG)** 내장.
- 연결 끊김/백그라운드 전환 시 즉시 `STP:` (안전 우선).
- 키트 프로파일이 사용 가능한 UI를 결정 — 메탈 RC카는 IR 라인 기능 자동 숨김.

## 실행 방법

이 저장소에는 `lib/` 소스와 `pubspec.yaml` 만 포함되어 있다. 플랫폼 폴더(android/ios)는
아래 명령으로 생성한다(기존 `lib/` 는 유지됨).

```bash
flutter create . --platforms=android,ios --project-name eduino_rc
flutter pub get
flutter run
```

### 플랫폼 권한 설정 (§3.3)

생성된 플랫폼 파일에 아래를 추가한다.

**Android** — `android/app/src/main/AndroidManifest.xml` (`<manifest>` 하위, `<application>` 위):
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<!-- Android 11 이하 스캔용 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" />
```
`android/app/build.gradle` 의 `minSdkVersion` 은 21 이상 권장.

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>RC카와 블루투스로 연결해 제어합니다.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>RC카와 블루투스로 연결해 제어합니다.</string>
```
> HC-06(Classic SPP)은 iOS에서 원천 불가 — 현재 스코프는 HM-10(BLE)만 지원(§2.1).

### 제품 실사진 에셋

`assets/kits/` 에 `two_wheel.png` · `metal.png` · `four_wheel.png` 를 넣으면 키트 카드에 자동 반영된다.
없으면 라인 아이콘 플레이스홀더로 폴백한다(§6.4 — 장식용 생성 이미지 금지).

### 폰트(선택)

계기 수치는 `google_fonts` 의 JetBrains Mono 를 런타임 로드한다. 본문용 Pretendard 를 쓰려면
`fonts/` 에 파일을 넣고 `pubspec.yaml` 의 fonts 주석을 해제한다.

## 프로토콜 요약 (§4)

라인 기반 ASCII `<CMD>:<args>\n` — "보이는 통신"이 곧 교보재.

| 방향 | 예 |
|---|---|
| App→Car | `DRV:80,-20` · `MOV:F` · `SPD:60` · `STP:` · `MOD:AUTO` · `PRM:DIST,25` · `PNG:` |
| Car→App | `DST:18` · `LIN:0,1,0` · `MOD:AUTO` · `BAT:87` · `ACK:MOD` · `LOG:...` |

펌웨어 참조 스켈레치는 `docs/spec.md` §7 참고.
