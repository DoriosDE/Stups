#!/usr/bin/env bash
# Prüft, ob eine gebaute APK die erwartete App-ID, Version und den erwarteten
# App-Namen hat. Läuft lokal (Git Bash) und in der CI.
#
# Aufruf: tool/verify_apk_version.sh <apk> <app-id> <versionName> <versionCode> <app-name>
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "Aufruf: $0 <apk> <app-id> <versionName> <versionCode> <app-name>" >&2
  exit 2
fi
apk=$1 expected_id=$2 expected_name=$3 expected_code=$4 expected_label=$5

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$sdk" ]; then
  echo "ANDROID_HOME ist nicht gesetzt." >&2
  exit 2
fi
if command -v cygpath >/dev/null 2>&1; then
  sdk=$(cygpath -u "$sdk")
fi

aapt2=$(ls -d "$sdk"/build-tools/*/aapt2* 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$aapt2" ]; then
  echo "aapt2 wurde in $sdk/build-tools nicht gefunden." >&2
  exit 2
fi

badging=$("$aapt2" dump badging "$apk")
package_line=$(printf '%s\n' "$badging" | grep -m1 '^package:')
label_line=$(printf '%s\n' "$badging" | grep -m1 '^application-label:')

actual_id=$(printf '%s' "$package_line" | sed -n "s/.* name='\([^']*\)'.*/\1/p")
actual_code=$(printf '%s' "$package_line" | sed -n "s/.* versionCode='\([^']*\)'.*/\1/p")
actual_name=$(printf '%s' "$package_line" | sed -n "s/.* versionName='\([^']*\)'.*/\1/p")
actual_label=$(printf '%s' "$label_line" | sed -n "s/^application-label:'\(.*\)'$/\1/p")

failed=0
check() {
  if [ "$2" != "$3" ]; then
    echo "FEHLER $1: erwartet '$3', gefunden '$2'" >&2
    failed=1
  else
    echo "ok     $1: $2"
  fi
}
check "App-ID     " "$actual_id" "$expected_id"
check "versionName" "$actual_name" "$expected_name"
check "versionCode" "$actual_code" "$expected_code"
check "App-Name   " "$actual_label" "$expected_label"
exit "$failed"
