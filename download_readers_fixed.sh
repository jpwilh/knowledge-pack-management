#!/usr/bin/env bash
# Robust script to download offline readers using curl with redirect follow

READER_DIR="notfall-pc/00_reader"
mkdir -p "$READER_DIR"

echo "Starte Download der Reader..."

download() {
    local url=$1
    local out="$READER_DIR/$2"
    echo "Lade: $2"
    # -L: Follow redirects
    # -f: Fail silently on server errors
    # -C -: Resume if possible
    curl -L -f -o "$out" "$url"
}

# Kiwix Android
download "https://download.kiwix.org/bin/android/kiwix-3.14.0.apk" "kiwix_android.apk"

# SumatraPDF (Windows)
download "https://www.sumatrapdfreader.org/dl/SumatraPDF-3.5.2-64.zip" "SumatraPDF_portable.zip"

# Kiwix Desktop Linux (via SourceForge mirrors)
download "https://downloads.sourceforge.net/project/kiwix/kiwix-desktop/kiwix-desktop_x86_64_2.5.1.appimage" "kiwix-desktop.AppImage"

# Kiwix Desktop Windows (via SourceForge mirrors)
download "https://downloads.sourceforge.net/project/kiwix/kiwix-desktop/kiwix-desktop_windows_x64_2.5.1.zip" "kiwix-desktop_windows.zip"

# Make Linux AppImage executable
chmod +x "$READER_DIR/kiwix-desktop.AppImage"

echo "Fertig! Alle Programme sind in $READER_DIR gespeichert."
