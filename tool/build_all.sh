#!/usr/bin/env bash
# Build APK dan web sekaligus.
set -e
cd "$(dirname "$0")/.."
bash tool/setup.sh
flutter build apk --release
flutter build web --release --pwa-strategy=none || flutter build web --release
echo
echo "APK : build/app/outputs/flutter-apk/app-release.apk"
echo "Web : build/web  (upload folder ini ke hosting HTTPS)"
