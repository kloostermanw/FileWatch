#!/bin/bash
# Build a Release FileWatch.app and package it into a drag-to-Applications .dmg.
#
# Code signing & notarization (required for the .dmg to open on other Macs) are
# OPT-IN via environment variables, because they need a Developer ID Application
# certificate and Apple credentials that aren't available in every environment:
#
#   DEVELOPER_ID_APP        e.g. "Developer ID Application: Your Name (TEAMID)"
#                           If unset, the app/dmg are left UNSIGNED (Gatekeeper will
#                           refuse to open them on any machine other than this one).
#   NOTARY_KEYCHAIN_PROFILE name of a profile stored via:
#                           xcrun notarytool store-credentials <profile> \
#                             --apple-id <id> --team-id <TEAMID> --password <app-specific-pw>
#                           If unset (or signing is skipped), notarization/stapling is skipped.
#
# Usage: scripts/make-dmg.sh
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="FileWatch"
DERIVED="build-release"
DMG_OUT="$APP_NAME.dmg"
ENTITLEMENTS="FileWatch/FileWatch.entitlements"

echo "==> Building Release"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  build >/dev/null

APP_PATH="$DERIVED/Build/Products/Release/$APP_NAME.app"
[ -d "$APP_PATH" ] || { echo "build failed: $APP_PATH missing" >&2; exit 1; }

SIGNED=0
if [ -n "${DEVELOPER_ID_APP:-}" ]; then
  echo "==> Code-signing $APP_NAME.app (hardened runtime) as: $DEVELOPER_ID_APP"
  if codesign --force --deep --options runtime --timestamp \
       ${ENTITLEMENTS:+--entitlements "$ENTITLEMENTS"} \
       --sign "$DEVELOPER_ID_APP" "$APP_PATH" \
     && codesign --verify --strict --verbose=2 "$APP_PATH"; then
    SIGNED=1
  else
    echo "==> WARNING: code-signing failed — identity \"$DEVELOPER_ID_APP\" not available in the keychain." >&2
    echo "    Continuing with an UNSIGNED app; the .dmg will be blocked by Gatekeeper on other Macs." >&2
  fi
else
  echo "==> WARNING: DEVELOPER_ID_APP not set — the app is UNSIGNED." >&2
  echo "    The resulting .dmg will be blocked by Gatekeeper on other Macs." >&2
fi

echo "==> Staging disk-image contents"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"   # drag-target for the user

echo "==> Creating $DMG_OUT"
rm -f "$DMG_OUT"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG_OUT" >/dev/null

if [ "$SIGNED" -eq 1 ]; then
  echo "==> Signing $DMG_OUT"
  codesign --force --timestamp --sign "$DEVELOPER_ID_APP" "$DMG_OUT"

  if [ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]; then
    echo "==> Notarizing $DMG_OUT (this can take a few minutes)"
    xcrun notarytool submit "$DMG_OUT" \
      --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
    echo "==> Stapling notarization ticket"
    xcrun stapler staple "$DMG_OUT"
    xcrun stapler validate "$DMG_OUT"
  else
    echo "==> WARNING: NOTARY_KEYCHAIN_PROFILE not set — skipping notarization." >&2
    echo "    A signed-but-un-notarized .dmg is still blocked by Gatekeeper on other Macs." >&2
  fi
fi

echo "==> Done: $(pwd)/$DMG_OUT"
