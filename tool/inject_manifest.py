#!/usr/bin/env python3
# Author: eduino
# flutter create 로 생성된 기본 AndroidManifest 에 BLE/위치 권한을 주입한다 (§3.3).
# CI 에서 platform 폴더를 새로 생성하므로, 빌드 전에 이 스크립트로 권한을 채운다. 멱등.

import sys
from pathlib import Path

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")

PERMISSIONS = """    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
"""


def main() -> int:
    if not MANIFEST.exists():
        print(f"[inject_manifest] not found: {MANIFEST}", file=sys.stderr)
        return 1

    text = MANIFEST.read_text(encoding="utf-8")

    import re as _re

    # tools 네임스페이스 보장 — INTERNET 제거 지시(tools:node="remove")에 필요.
    if "xmlns:tools=" not in text:
        text2 = _re.sub(r"(<manifest\b)",
                        r'\1 xmlns:tools="http://schemas.android.com/tools"',
                        text, count=1)
        if text2 != text:
            text = text2
            MANIFEST.write_text(text, encoding="utf-8")
            print("[inject_manifest] xmlns:tools added")

    # INTERNET 권한 제거(오프라인 앱) — main 매니페스트에 직접 선언돼 있으면 삭제.
    # 병합(manifest-merger)으로 의존성이 다시 추가하는 경우는 PERMISSIONS 의
    # tools:node="remove" 지시가 최종 병합 결과에서 제거한다.
    text_no_net = _re.sub(
        r'\s*<uses-permission(?![^>]*tools:node)[^>]*android\.permission\.INTERNET[^>]*/>',
        '', text)
    if text_no_net != text:
        text = text_no_net
        MANIFEST.write_text(text, encoding="utf-8")
        print("[inject_manifest] INTERNET permission removed (offline app)")

    # 런처 라벨 통일(앱 이름) — flutter create 기본값(eduino_rc) → 표시명.
    text2 = _re.sub(r'android:label="[^"]*"',
                    'android:label="Eduino Bluetooth Controller"', text, count=1)
    if text2 != text:
        text = text2
        MANIFEST.write_text(text, encoding="utf-8")
        print("[inject_manifest] android:label set")

    if "BLUETOOTH_SCAN" in text:
        print("[inject_manifest] permissions already present, skip")
        return 0

    lines = text.splitlines(keepends=True)
    out = []
    injected = False
    for line in lines:
        out.append(line)
        if not injected and "<manifest" in line and ">" in line:
            out.append(PERMISSIONS)
            injected = True

    if not injected:
        print("[inject_manifest] <manifest> tag not found", file=sys.stderr)
        return 1

    MANIFEST.write_text("".join(out), encoding="utf-8")
    print("[inject_manifest] BLE permissions injected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
