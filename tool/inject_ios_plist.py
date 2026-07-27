#!/usr/bin/env python3
# Author: eduino
# flutter create 로 생성된 ios/Runner/Info.plist 에 권한 사용 사유 문구를 주입한다.
#   · NSBluetoothAlwaysUsageDescription / NSBluetoothPeripheralUsageDescription (BLE)
#   · NSMicrophoneUsageDescription / NSSpeechRecognitionUsageDescription (음성 제어)
# iOS 는 HM-10(BLE) 전용 — Classic SPP 관련 키는 넣지 않는다. 멱등.

import re
import sys
from pathlib import Path

PLIST = Path("ios/Runner/Info.plist")
PBXPROJ = Path("ios/Runner.xcodeproj/project.pbxproj")
BUNDLE_ID = "kr.eduino.ble"

KEYS = {
    "NSBluetoothAlwaysUsageDescription":
        "RC카·스마트 교구를 블루투스로 연결·제어하기 위해 블루투스를 사용합니다.",
    "NSBluetoothPeripheralUsageDescription":
        "RC카·스마트 교구를 블루투스로 연결·제어하기 위해 블루투스를 사용합니다.",
    "NSMicrophoneUsageDescription":
        "음성 명령으로 RC카를 조작하기 위해 마이크를 사용합니다.",
    "NSSpeechRecognitionUsageDescription":
        "음성 명령을 인식하기 위해 음성 인식을 사용합니다(온디바이스).",
}


def patch_bundle_id() -> None:
    """iOS 번들 식별자를 kr.eduino.ble 로 고정(테스트 타깃은 .RunnerTests)."""
    if not PBXPROJ.exists():
        print(f"[inject_ios_plist] pbxproj not found: {PBXPROJ}", file=sys.stderr)
        return
    text = PBXPROJ.read_text(encoding="utf-8")
    # RunnerTests 타깃 먼저(하위 식별자 유지).
    text = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*\.RunnerTests;',
                  f'PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}.RunnerTests;', text)
    # 나머지(메인 앱) — 이미 목표값이면 건너뜀.
    text = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = (?!' + re.escape(BUNDLE_ID) + r')[^;]*;',
                  f'PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};', text)
    PBXPROJ.write_text(text, encoding="utf-8")
    print(f"[inject_ios_plist] bundle identifier set to {BUNDLE_ID}")


def main() -> int:
    patch_bundle_id()
    if not PLIST.exists():
        print(f"[inject_ios_plist] not found: {PLIST}", file=sys.stderr)
        return 1
    text = PLIST.read_text(encoding="utf-8")
    entries = ""
    for key, desc in KEYS.items():
        if f"<key>{key}</key>" in text:
            continue
        entries += f"\t<key>{key}</key>\n\t<string>{desc}</string>\n"
    if not entries:
        print("[inject_ios_plist] all keys already present, skip")
        return 0
    marker = "<dict>"
    idx = text.find(marker)
    if idx < 0:
        print("[inject_ios_plist] <dict> not found", file=sys.stderr)
        return 1
    idx += len(marker)
    text = text[:idx] + "\n" + entries + text[idx:]
    PLIST.write_text(text, encoding="utf-8")
    print("[inject_ios_plist] usage descriptions injected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
