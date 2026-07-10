# CLAUDE.md — EDUINO RC카 컨트롤러

작업 기준 스펙: `docs/spec.md` (업로드 원본). 이 파일은 코드 규칙 요약이다.

## 아키텍처 규칙 (강제)
- **상태관리는 Riverpod**. 전역 상태(연결·텔레메트리·키트)는 provider 로만 노출.
- **통신은 반드시 `BtTransport` 경유**. 화면/위젯이 `flutter_blue_plus`(또는 `flutter_bluetooth_serial`)를 **직접 import 금지**. 오직 `core/bt/` 와 `providers/` 만 통신 패키지를 안다.
- **모든 주행 명령 전송 지점**: `CarController` 를 통해서만 보내고, `CarController` 안에 **송신 스로틀링 + 연결 상태 가드**가 들어있다. 화면이 raw `transport.send()` 를 부르지 않는다.
- **안전 우선**: 연결 끊김/백그라운드 전환 시 즉시 `STP:`. 하트비트(`PNG:`) 주기 전송.
- **키트 프로파일이 사용 가능한 모드/UI를 결정**한다. 메탈 RC카는 IR 라인센서가 없으므로 라인트레이싱 자율주행·라인 텔레메트리 UI를 자동 숨김.
- HC-06(SPP)은 Android 전용(`Platform.isAndroid` 가드) — 현재 스코프(P0–P5)에는 미포함, `SppTransport` 슬롯만.

## 코드 규칙
- 파일 헤더 주석 author = `eduino`, 프로젝트명 미표기.
- 프로토콜은 §4 의 라인 기반 ASCII(`<CMD>:<args>\n`). "보이는 통신" = 교보재.
- BLE 1회 write 20바이트 제한 → 긴 프레임 분할. Notify 조각 → `\n` 기준 재조립 버퍼.

## 디자인 완성도 규칙 (§6.4)
- 장식용 SVG 도형·그라디언트 배경·생성형 플레이스홀더 **금지**. 여백·타이포·실제 데이터 컴포넌트로 화면 구성.
- 게이지/조이스틱/센서 표시는 **커스텀 위젯으로 정성껏**(대충 만든 원/사각형 금지).
- 제품 이미지는 실사진 에셋 슬롯(`assets/kits/`)으로 구조화. EDUINO 실사진을 넣도록 비워둔다.
- 일관된 라인 아이콘 한 패밀리, 8pt 그리드, 절제된 모션, 주요 조작에 햅틱.

## 폴더 구조
```
lib/
├── app/        # theme.dart, router.dart
├── core/
│   ├── protocol/   # commands.dart, telemetry.dart
│   └── bt/         # bt_transport.dart, ble_transport.dart
├── features/   # kit, connect, terminal, controller, joystick, autonomous, hub
├── widgets/    # 게이지·상태바·센서 표시 등 공용
└── providers/  # Riverpod providers
```

## 현재 구현 범위
P0(스캐폴딩·테마·라우팅) ~ P5(자율주행·실험 모드). LED/기울기/음성/미션/코드매핑/HC-06/폴리싱은 후속(P6–P10).
