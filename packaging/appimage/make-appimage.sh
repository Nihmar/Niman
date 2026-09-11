#!/usr/bin/env bash
# Build a Niman AppImage from a Flutter Linux release bundle.
#
# Usage:
#   packaging/appimage/make-appimage.sh <bundle-dir> <icon-png> <version> <output>
#
#   <bundle-dir>  e.g. build/linux/x64/release/bundle (contains niman,
#                 data/, lib/ and dev.niman.niman.desktop)
#   <icon-png>    e.g. assets/branding/app_icon.png
#   <version>     e.g. 1.2.3 (used for update info only)
#   <output>      e.g. dist/niman-1.2.3-linux-x64.AppImage
#
# Needs network once (downloads appimagetool unless APPIMAGETOOL points at
# one). Set APPIMAGETOOL to reuse a local binary.
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <bundle-dir> <icon-png> <version> <output>" >&2
  exit 1
fi

BUNDLE="$1"
ICON="$2"
VERSION="$3"
OUTPUT="$4"

for f in "$BUNDLE/niman" "$BUNDLE/dev.niman.niman.desktop" "$ICON"; do
  if [ ! -e "$f" ]; then
    echo "error: missing input $f" >&2
    exit 1
  fi
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APPDIR="$STAGE/Niman.AppDir"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# The Flutter bundle is self-contained (exe + data + lib): ship it as-is.
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"

cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/niman" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# AppDir root entry point: desktop file + matching icon. Only the Icon is
# rewritten; Exec lines keep their flags (quick actions included).
sed -e 's|^Icon=.*|Icon=niman|' \
  "$BUNDLE/dev.niman.niman.desktop" > "$APPDIR/niman.desktop"
cp "$ICON" "$APPDIR/niman.png"
cp "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/niman.png"

if [ -n "${APPIMAGETOOL:-}" ]; then
  TOOL="$APPIMAGETOOL"
else
  TOOL="$STAGE/appimagetool-x86_64.AppImage"
  curl -fsSL -o "$TOOL" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$TOOL"
fi

mkdir -p "$(dirname "$OUTPUT")"
# The tool itself is an AppImage: FUSE is not available on CI runners,
# so run it extracted.
export APPIMAGE_EXTRACT_AND_RUN=1
"$TOOL" "$APPDIR" "$OUTPUT"
echo "artifact: $OUTPUT"
