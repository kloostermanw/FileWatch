#!/bin/bash
# Set MARKETING_VERSION in the Xcode project to match a release tag.
# Called by git-release as cmd1 (before the tag is created), so the version
# bump is baked into the tagged commit. git-release stages and commits
# project.pbxproj afterwards (cmd1_filename).
# Usage: scripts/set-version.sh --release v1.2.3
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="FileWatch.xcodeproj/project.pbxproj"

TAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --release) TAG="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$TAG" ] || { echo "set-version: --release <tag> is required" >&2; exit 2; }

# Strip a leading v/V; MARKETING_VERSION is a plain dotted number.
VERSION="${TAG#[vV]}"

case "$VERSION" in
  *[!0-9.]*|"") echo "set-version: '$TAG' is not a numeric version" >&2; exit 2 ;;
esac

grep -q 'MARKETING_VERSION = ' "$PROJECT" || {
  echo "set-version: MARKETING_VERSION not found in $PROJECT" >&2; exit 1; }

# Replace every MARKETING_VERSION value (Debug + Release configs).
/usr/bin/sed -i '' -E "s/(MARKETING_VERSION = )[^;]*(;)/\1${VERSION}\2/g" "$PROJECT"

# sed exits 0 even when it replaces nothing; confirm the value actually took so a
# release can never be tagged from a commit with a stale MARKETING_VERSION.
grep -q "MARKETING_VERSION = ${VERSION};" "$PROJECT" || {
  echo "set-version: replacement did not take; MARKETING_VERSION is not ${VERSION}" >&2; exit 1; }

echo "set-version: MARKETING_VERSION -> ${VERSION}"
