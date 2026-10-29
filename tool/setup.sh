#!/usr/bin/env bash
# Menyiapkan folder android/ dan web/, izin Android, dan ikon. Aman dijalankan berulang.
set -e
cd "$(dirname "$0")/.."

if [ ! -d android ] || [ ! -d web ]; then
  flutter create --platforms=android,web --org id.misyi --project-name lid .
fi
rm -rf test
flutter pub get

M=android/app/src/main/AndroidManifest.xml
if ! grep -q 'android.permission.CAMERA' "$M"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.CAMERA"/>\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <uses-feature android:name="android.hardware.camera" android:required="false"/>\n    <application#' "$M"
fi
perl -pi -e 's/android:label="[^"]*"/android:label="lid"/' "$M"

for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && perl -pi -e 's/minSdk(Version)?\s*(=\s*)?flutter\.minSdkVersion/minSdk = 24/' "$f"
done

dart run flutter_launcher_icons
echo "Setup selesai."
