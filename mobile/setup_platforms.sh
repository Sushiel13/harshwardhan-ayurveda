#!/usr/bin/env bash
# Generates the android/ and ios/ folders for this Flutter app and applies the
# settings the app needs. Run once from the mobile/ folder:  bash setup_platforms.sh
set -euo pipefail

ORG="in.harshwardhanayurveda"
NAME="harshwardhan_ayurveda"

flutter create --org "$ORG" --project-name "$NAME" --platforms android,ios .

MANIFEST=android/app/src/main/AndroidManifest.xml
# 1) Internet permission (release builds need it explicitly)
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi
# 2) Friendly app name on the home screen
sed -i.bak 's#android:label="[^"]*"#android:label="Harshwardhan Ayurveda"#' "$MANIFEST"
rm -f "$MANIFEST.bak"

# 3) Razorpay + video player need minSdk 21+
for f in android/app/build.gradle android/app/build.gradle.kts; do
  if [ -f "$f" ]; then
    sed -i.bak -E 's/minSdk(Version)? *=? *flutter\.minSdkVersion/minSdk = 23/' "$f" || true
    rm -f "$f.bak"
  fi
done

# 4) iOS display name
PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Harshwardhan Ayurveda'" "$PLIST" 2>/dev/null || true
fi

flutter pub get
echo ""
echo "✓ Platforms ready. Next: flutter run --dart-define-from-file=env.json"
