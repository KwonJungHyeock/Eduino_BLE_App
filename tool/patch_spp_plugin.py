#!/usr/bin/env python3
# Author: eduino
# flutter_bluetooth_serial(0.4.0)는 AGP 8 의 namespace 요구 이전 플러그인이라 그대로는 빌드 실패한다.
# CI 에서 pub 캐시의 플러그인 android 설정을 패치:
#   1) android/build.gradle 의 android{} 에 namespace 추가
#   2) AndroidManifest.xml 의 package 속성 제거(AGP8은 namespace 로 대체)
# 멱등. 플러그인이 없으면(=미사용) 조용히 통과.

import glob
import os
import re
import sys

NAMESPACE = "io.github.edufolly.flutterbluetoothserial"


def find_plugin_dir() -> str | None:
    roots = []
    pub_cache = os.environ.get("PUB_CACHE")
    if pub_cache:
        roots.append(pub_cache)
    roots.append(os.path.expanduser("~/.pub-cache"))
    for root in roots:
        hits = glob.glob(
            os.path.join(root, "hosted", "*", "flutter_bluetooth_serial-*")
        )
        if hits:
            return sorted(hits)[-1]
    return None


def patch_build_gradle(plugin_dir: str) -> None:
    path = os.path.join(plugin_dir, "android", "build.gradle")
    if not os.path.exists(path):
        print(f"[patch_spp] no build.gradle at {path}")
        return
    text = open(path, encoding="utf-8").read()
    if "namespace" in text:
        print("[patch_spp] namespace already present")
        return
    # android { 바로 다음 줄에 namespace 삽입
    new_text, n = re.subn(
        r"(android\s*\{)",
        r'\1\n    namespace "%s"' % NAMESPACE,
        text,
        count=1,
    )
    if n == 0:
        print("[patch_spp] 'android {' block not found", file=sys.stderr)
        return
    open(path, "w", encoding="utf-8").write(new_text)
    print("[patch_spp] namespace injected into build.gradle")


def patch_manifest(plugin_dir: str) -> None:
    path = os.path.join(
        plugin_dir, "android", "src", "main", "AndroidManifest.xml"
    )
    if not os.path.exists(path):
        print(f"[patch_spp] no manifest at {path}")
        return
    text = open(path, encoding="utf-8").read()
    new_text = re.sub(r'\s*package="[^"]*"', "", text, count=1)
    if new_text != text:
        open(path, "w", encoding="utf-8").write(new_text)
        print("[patch_spp] removed package attr from manifest")
    else:
        print("[patch_spp] manifest package attr not found (ok)")


def main() -> int:
    plugin_dir = find_plugin_dir()
    if not plugin_dir:
        print("[patch_spp] plugin not found in pub cache — skip")
        return 0
    print(f"[patch_spp] plugin dir: {plugin_dir}")
    patch_build_gradle(plugin_dir)
    patch_manifest(plugin_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
