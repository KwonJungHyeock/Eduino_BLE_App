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
"""


def main() -> int:
    if not MANIFEST.exists():
        print(f"[inject_manifest] not found: {MANIFEST}", file=sys.stderr)
        return 1

    text = MANIFEST.read_text(encoding="utf-8")
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
