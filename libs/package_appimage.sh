#!/usr/bin/env bash
set -Eeuo pipefail

APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
APPIMAGETOOL="appimagetool-x86_64.AppImage"
APPDIR="nekobox.AppDir"
OUTPUT="nekobox-x86_64.AppImage"

cleanup() {
    rm -f "${APPIMAGETOOL}"
    rm -rf "${APPDIR}"
}
trap cleanup EXIT

sudo apt-get install fuse -y

rm -rf "${APPDIR}"
cp -a linux64 "${APPDIR}"

# Prepare the AppImage desktop entry and launcher.
rm -f "${APPDIR}/launcher"

cat > "${APPDIR}/nekobox.desktop" <<'EOF'
[Desktop Entry]
Name=nekobox
Exec=echo "nekobox started"
Icon=nekobox
Type=Application
Categories=Network
EOF

cat > "${APPDIR}/AppRun" <<'EOF'
#!/bin/bash
echo "PATH: ${PATH}"
echo "nekobox running on: $APPDIR"
LD_LIBRARY_PATH=${APPDIR}/usr/lib QT_PLUGIN_PATH=${APPDIR}/usr/plugins ${APPDIR}/nekobox -appdata "$@"
EOF

chmod +x "${APPDIR}/AppRun"

# AppImageKit's old AppImageKit release is explicitly marked obsolete.
# Use the maintained appimagetool continuous release instead.
curl \
    --fail \
    --location \
    --show-error \
    --silent \
    --retry 5 \
    --retry-all-errors \
    --retry-delay 2 \
    --retry-max-time 120 \
    --connect-timeout 20 \
    --max-time 300 \
    --output "${APPIMAGETOOL}" \
    "${APPIMAGETOOL_URL}"

if [[ ! -s "${APPIMAGETOOL}" ]]; then
    echo "error: appimagetool download is empty" >&2
    exit 1
fi

chmod +x "${APPIMAGETOOL}"
"./${APPIMAGETOOL}" "${APPDIR}"

if [[ ! -s "${OUTPUT}" ]]; then
    echo "error: appimagetool did not create ${OUTPUT}" >&2
    exit 1
fi
