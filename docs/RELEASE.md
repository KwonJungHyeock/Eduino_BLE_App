# EDUINO 앱 — 배포 런북 (Android AAB + iOS)

배포 체크리스트(`docs/…배포 체크리스트`) 실행 가이드. **코드/CI로 자동화된 부분**과 **사람이 직접 해야 하는 부분**을 구분한다.

---

## 0. 앱 아이덴티티 (확정됨)
| 항목 | 값 |
|---|---|
| 버전 | `1.0.0+1` (`pubspec.yaml`) |
| Android applicationId | `kr.eduino.eduino_rc` (`flutter create --org kr.eduino --project-name eduino_rc`) |
| iOS bundleIdentifier | `kr.eduino.eduino_rc` (동일 계열) |
| compileSdk / targetSdk | **35** (Android 15 · 2026 Play 필수) |
| minSdk | **23** (BLE 권장) |
| iOS 통신 | **HM-10(BLE) 전용** — HC-06(Classic SPP)는 iOS에서 UI 숨김 |

> applicationId를 `kr.eduino.ble` 등으로 바꾸려면 워크플로의 `--org`/`--project-name`과 이 문서를 함께 수정.

---

## 1. 자동화된 것 (이 저장소 / CI)
- **릴리스 AAB 빌드**: `.github/workflows/build-release.yml` (수동 트리거) → `flutter build appbundle --release --obfuscate --split-debug-info` → AAB + 심볼 아티팩트.
- **targetSdk 35 / minSdk 23 / 서명 설정**: `tool/patch_release_gradle.py` (CI가 `flutter create` 후 `build.gradle.kts` 패치).
- **Android 권한**: `tool/inject_manifest.py` — `BLUETOOTH_SCAN`(`neverForLocation`)·`BLUETOOTH_CONNECT`·레거시(`BLUETOOTH`/`BLUETOOTH_ADMIN`/`ACCESS_FINE_LOCATION` maxSdk 30)·`RECORD_AUDIO`. `INTERNET` 미포함(오프라인 앱).
- **iOS 권한 문구**: `tool/inject_ios_plist.py` — `NSBluetoothAlwaysUsageDescription`·`NSBluetoothPeripheralUsageDescription`·`NSMicrophoneUsageDescription`·`NSSpeechRecognitionUsageDescription`.
- **아이콘·스플래시**: `pubspec.yaml`의 `flutter_launcher_icons`/`flutter_native_splash` (CI에서 생성) — 코랄 브랜드 마크.
- **iOS 릴리스 컴파일 검증**: 워크플로 `ios-validate` 잡 (`flutter build ios --release --no-codesign`).

---

## 2. 사람이 해야 하는 것 (보안·계정 필요)

### 2-1. Android 업로드 키스토어 생성 (★1순위)
로컬에서 1회 생성 후 **안전하게 백업**(분실 시 업데이트 불가):
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# 비밀번호·이름·조직 입력. 생성된 upload-keystore.jks 를 안전한 곳에 보관.
```
base64로 인코딩:
```bash
base64 -w0 upload-keystore.jks > keystore.b64   # macOS: base64 -i upload-keystore.jks -o keystore.b64
```

### 2-2. GitHub Secrets 등록
저장소 → Settings → Secrets and variables → Actions → New repository secret 로 **4개** 등록:
| Secret | 값 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `keystore.b64` 내용 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 스토어 비밀번호 |
| `ANDROID_KEY_ALIAS` | `upload` (또는 지정한 별칭) |
| `ANDROID_KEY_PASSWORD` | 키 비밀번호 |

> Secret이 없으면 워크플로는 **debug 서명으로 폴백**해 빌드 자체는 검증되지만, Play 업로드는 불가. Secret 등록 후 재실행하면 서명된 AAB가 나온다.

### 2-3. 릴리스 빌드 실행
저장소 → Actions → **Build Release** → Run workflow → 브랜치 선택 → 실행.
완료되면 `eduino-rc-release-aab` 아티팩트(= `app-release.aab`) 다운로드.

### 2-4. Play App Signing
Play Console에 AAB 첫 업로드 시 **Play App Signing** 활성화(구글이 앱 서명키 관리, 우리는 업로드키만 보관). 업로드키 분실 대비 백업 필수.

### 2-5. iOS 서명·업로드 (Apple 계정 필요)
CI의 `ios-validate`는 **미서명 컴파일 검증**까지만 한다. 실제 제출은:
1. **Apple Developer Program** 가입(연 $99).
2. **Distribution Certificate** + **App Store Provisioning Profile** 생성.
3. App Store Connect에 앱 레코드 생성(Bundle ID `kr.eduino.eduino_rc` 등록).
4. Xcode(또는 Transporter)로 아카이브 → 업로드. (CI 서명 자동화는 인증서/프로파일을 secret으로 넣어 `fastlane match`/`codesign` 구성 시 가능 — 필요 시 추가 작업.)

---

## 3. 개인정보 & 컴플라이언스 (교육앱)
- **개인정보처리방침 URL**: 앱 내 `개인정보` 화면 문안을 웹에 게시하고 URL 확보(데이터 미수집·오프라인 동작 명시). Play/App Store 등록 시 필수.
- **Play 데이터 안전(Data Safety)**: 수집·공유 **없음**으로 선언(광고·분석 SDK 없음).
- **Apple 개인정보 라벨**: 수집 없음.
- **대상 연령**: 아동/청소년 → Play **Families 정책** 준수(제3자 데이터수집 SDK 없어야 유리). 현재 앱은 광고·분석 SDK 없음.
- **음성 인식**: `speech_to_text` 온디바이스 우선.
- 콘텐츠 등급: Play IARC 설문 / Apple 연령 등급.

---

## 4. 배포 전 QA (실기기 · 하드웨어 필요)
- 6개 키트 실연결(HM-10 iOS/Android, HC-06 Android), 자동 재연결, 끊김/백그라운드 즉시 정지(STP).
- 권한 거부/블루투스 꺼짐/기기 없음 에러 경로.
- 폰/태블릿·회전, 저사양 기기, 오프라인 전 기능.
- 빠른 명령 연타(스로틀링)·장시간 주행 메모리.
- Living Twin 반응·모니터링 수신값 실데이터 검증.
- 다크모드: 현재 라이트 고정(다크 미대응) — 강제 라이트 확인.

---

## 5. 남은 선택 항목
- **R8 minify/shrink**: 현재 릴리스는 minify 비활성(BLE 플러그인 keep 규칙 필요). 활성화하려면 `android/app/proguard-rules.pro`에 `flutter_blue_plus`/`flutter_bluetooth_serial` keep 규칙 추가 후 `patch_release_gradle.py`에서 `isMinifyEnabled=true` 설정.
- **스토어 자산**: 피처 그래픽(1024×500), 스크린샷(폰/태블릿), 설명, 카테고리=교육, 미리보기 영상(선택).
- **크래시 모니터링**: 개인정보 영향 없는 방식 선택 시 도입.
