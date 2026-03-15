#!/usr/bin/env bash
# Script to download offline readers for ZIM and PDF files
# Targets Linux, Windows, and Android to ensure portability.

READER_DIR="$(dirname "$0")"
mkdir -p "$READER_DIR"

# URLs
KIWIX_LINUX_URL="https://download.kiwix.org/bin/kiwix-desktop_x86_64.appimage"
KIWIX_WINDOWS_URL="https://download.kiwix.org/bin/windows/kiwix-desktop_windows_x64.zip"
KIWIX_ANDROID_URL="https://download.kiwix.org/bin/android/kiwix-3.14.0.apk"
SUMATRA_PDF_URL="https://www.sumatrapdfreader.org/dl/SumatraPDF-3.5.2-64.zip"

echo "Lade Reader-Tools herunter..."

# Function for clean downloads
download() {
    local url=$1
    local out=$2
    if [[ -f "$out" ]]; then
        echo "Datei existiert bereits: $out"
    else
        echo "Lade herunter: $out"
        curl -L -o "$out" "$url"
    fi
}

# Download tools
download "$KIWIX_LINUX_URL" "$READER_DIR/kiwix-desktop.AppImage"
download "$KIWIX_WINDOWS_URL" "$READER_DIR/kiwix-desktop_windows.zip"
download "$KIWIX_ANDROID_URL" "$READER_DIR/kiwix_android.apk"
download "$SUMATRA_PDF_URL" "$READER_DIR/SumatraPDF_portable.zip"

# Make Linux AppImage executable
chmod +x "$READER_DIR/kiwix-desktop.AppImage"

echo "Fertig! Alle Tools befinden sich in: $READER_DIR"
echo "Tipp: Das .AppImage kann unter Linux direkt mit ./kiwix-desktop.AppImage gestartet werden."
