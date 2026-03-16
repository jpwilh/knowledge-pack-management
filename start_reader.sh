#!/bin/bash
# start_reader.sh - Startet den grafischen Kiwix-Reader (Extract-and-Run)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nutze den Mountpoint aus der Umgebung oder falle auf das lokale Verzeichnis zurück
BASE_DIR="${NOTFALL_PC_MOUNT:-$SOURCE_DIR}"
READER="${BASE_DIR}/notfall-pc/00_reader/kiwix-desktop.AppImage"

if [ ! -f "$READER" ]; then
    echo "FEHLER: Reader nicht gefunden unter: $READER"
    echo "Ist dein Notfall-PC (USB/HDD) gemountet? (NOTFALL_PC_MOUNT=${NOTFALL_PC_MOUNT})"
    exit 1
fi

chmod +x "$READER"
echo "[*] Starte Kiwix Desktop von: $READER"
echo "[*] Nutze --appimage-extract-and-run (kein FUSE notwendig)"

# Starte den Reader
"$READER" --appimage-extract-and-run &
