#!/usr/bin/env python3
# Author: eduino
# flutter create 로 생성된 android/app/build.gradle.kts 를 릴리스 배포용으로 패치한다.
#   · compileSdk / targetSdk = 35 (2026 Play 필수), minSdk = 23 (BLE 권장)
#   · 업로드 키스토어 서명(key.properties 존재 시). 없으면 debug 서명으로 폴백(파이프라인 검증용).
# R8 minify 는 BLE 플러그인 keep 규칙이 필요해 기본 비활성(문서 참고). 멱등.

import re
import sys
from pathlib import Path

KTS = Path("android/app/build.gradle.kts")
GROOVY = Path("android/app/build.gradle")
MARK = "EDUINO-RELEASE-PATCH"

IMPORTS = "import java.util.Properties\nimport java.io.FileInputStream\n"

LOADER = """
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
"""

SIGNING = """    signingConfigs {
        create("release") {
            if (rootProject.file("key.properties").exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
"""

RELEASE_BUILDTYPE = """        release {
            signingConfig = if (rootProject.file("key.properties").exists())
                signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }"""


def patch_kts(t: str) -> str:
    if MARK in t:
        print("[patch_release_gradle] already patched, skip")
        return t
    t = IMPORTS + t
    # keystore 로더를 android { 블록 앞에 삽입.
    t = re.sub(r"\nandroid\s*\{", LOADER + "\nandroid {", t, count=1)
    # SDK 버전 상향(Flutter 관리값 → 고정값).
    t = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion", "compileSdk = 35", t)
    t = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", t)
    t = re.sub(r"targetSdk\s*=\s*flutter\.targetSdkVersion", "targetSdk = 35", t)
    # signingConfigs 블록을 android { 바로 다음에 주입.
    t = re.sub(r"(\nandroid\s*\{\n)", r"\1" + SIGNING, t, count=1)
    # buildTypes 의 release 를 릴리스 서명으로 교체.
    t2 = re.sub(
        r"        release\s*\{\s*\n\s*signingConfig\s*=\s*signingConfigs\.getByName\(\"debug\"\)\s*\n\s*\}",
        RELEASE_BUILDTYPE,
        t,
    )
    if t2 == t:
        print("[patch_release_gradle] WARN: release buildType pattern not found — "
              "signingConfig 미교체(수동 확인 필요)", file=sys.stderr)
    t = t2 + f"\n// {MARK} applied\n"
    return t


def main() -> int:
    if KTS.exists():
        src = KTS.read_text(encoding="utf-8")
        KTS.write_text(patch_kts(src), encoding="utf-8")
        print("[patch_release_gradle] patched build.gradle.kts (compile/target 35, minSdk 23, signing)")
        return 0
    if GROOVY.exists():
        print("[patch_release_gradle] found Groovy build.gradle — "
              "이 프로젝트는 Kotlin DSL 기대. 수동 확인 필요.", file=sys.stderr)
        return 1
    print("[patch_release_gradle] build.gradle(.kts) not found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
