#!/usr/bin/env python3
# Author: eduino
# flutter create 로 생성된 android/app/build.gradle.kts 를 릴리스 배포용으로 패치한다.
#   · applicationId = kr.eduino.ble (스토어 패키지명 고정)
#   · compileSdk / targetSdk = 36 (2026-08 Play 업데이트 필수 · Android 16), minSdk = 23 (BLE 권장)
#   · release: minifyEnabled=true, shrinkResources=true, debuggable=false + proguard-rules.pro
#   · 업로드 키스토어 서명(key.properties 존재 시). 없으면 debug 서명으로 폴백(파이프라인 검증용).
# R8 minify keep 규칙은 proguard-rules.pro 로 함께 기록(BLE/권한/센서/음성 플러그인 보존). 멱등.

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
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (rootProject.file("key.properties").exists())
                signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }"""

# R8/shrink 시 리플렉션·플러그인 채널이 제거되지 않도록 보존 규칙(오프라인 교육용 앱).
PROGUARD_RULES = """# Author: eduino — 릴리스 R8 keep 규칙(멱등 자동 생성)
# Flutter 임베딩
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
# Play Core (deferred component 미사용이나 기본 규칙이 참조)
-dontwarn com.google.android.play.core.**
# BLE(HM-10)·SPP(HC-06)
-keep class com.lib.flutter_blue_plus.** { *; }
-keep class com.boskokg.flutter_blue_plus.** { *; }
-keep class io.github.edufolly.flutterbluetoothserial.** { *; }
# 권한·센서·음성 플러그인
-keep class com.baseflow.permissionhandler.** { *; }
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-keep class com.csdcorp.speech_to_text.** { *; }
"""


def patch_kts(t: str) -> str:
    if MARK in t:
        print("[patch_release_gradle] already patched, skip")
        return t
    t = IMPORTS + t
    # keystore 로더를 android { 블록 앞에 삽입.
    t = re.sub(r"\nandroid\s*\{", LOADER + "\nandroid {", t, count=1)
    # 스토어 패키지명 고정(flutter create --org 파생값 → kr.eduino.ble).
    t = re.sub(r'applicationId\s*=\s*"[^"]*"',
               'applicationId = "kr.eduino.ble"', t, count=1)
    # SDK 버전 상향(Flutter 관리값 → 고정값).
    t = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion", "compileSdk = 36", t)
    t = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", t)
    t = re.sub(r"targetSdk\s*=\s*flutter\.targetSdkVersion", "targetSdk = 36", t)
    # signingConfigs 블록을 android { 바로 다음에 주입.
    t = re.sub(r"(\nandroid\s*\{\n)", r"\1" + SIGNING, t, count=1)
    # buildTypes 의 release 블록 전체를 릴리스 서명+minify 로 교체.
    # flutter create 템플릿은 `release {` 와 `signingConfig` 사이에 주석 2줄을 넣으므로
    # 블록 내부(중괄호 없음)를 [^}]* 로 유연 매칭한다(주석/공백 허용).
    t2, n = re.subn(
        r'release\s*\{[^}]*?signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)[^}]*?\}',
        RELEASE_BUILDTYPE.strip(),
        t,
        count=1,
    )
    if n == 0:
        # 조용한 debug 서명 폴백 방지 — 매칭 실패 시 빌드를 명확히 실패시킨다.
        raise SystemExit(
            "[patch_release_gradle] FATAL: release buildType 패턴 미매칭 — "
            "signingConfig/minify 미적용. 템플릿 변경 확인 필요(디버그 서명 폴백 차단)."
        )
    t = t2 + f"\n// {MARK} applied\n"
    return t


def main() -> int:
    if KTS.exists():
        src = KTS.read_text(encoding="utf-8")
        KTS.write_text(patch_kts(src), encoding="utf-8")
        # R8 keep 규칙 파일 기록(멱등 — 항상 최신 규칙으로 덮어씀).
        Path("android/app/proguard-rules.pro").write_text(
            PROGUARD_RULES, encoding="utf-8")
        print("[patch_release_gradle] patched build.gradle.kts "
              "(applicationId kr.eduino.ble, compile/target 36, minSdk 23, "
              "minify+shrink, signing) + proguard-rules.pro")
        return 0
    if GROOVY.exists():
        print("[patch_release_gradle] found Groovy build.gradle — "
              "이 프로젝트는 Kotlin DSL 기대. 수동 확인 필요.", file=sys.stderr)
        return 1
    print("[patch_release_gradle] build.gradle(.kts) not found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
