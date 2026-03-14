#!/usr/bin/env bash
# Notfall-PC Download Status Dashboard (Maintenance v2)

# PATHS - Corrected to detected drive
TARGET_DIR="/media/jpw/NOTFALL_PC/notfall-pc"
LOG_DIR="$TARGET_DIR/99_meta"
SCRIPT_DIR="/home/jpw/knowledge-pack-management"

echo "========================================================"
echo "   NOTFALL-PC DOWNLOAD DASHBOARD (NOTFALL_PC DRIVE)"
echo "========================================================"

# 1. Prozess-Status (Watchdog & Main Script)
if pgrep -f "watchdog.sh" > /dev/null; then
    echo -e "Watchdog: \033[0;32mAKTIV\033[0m"
else
    echo -e "Watchdog: \033[0;31mINAKTIV (Keine automatische Überwachung)\033[0m"
fi

if pgrep -f "offline_knowledge_pack_v3_de.sh" > /dev/null; then
    echo -e "Status:   \033[0;32mAKTIV (Skript läuft im Hintergrund)\033[0m"
else
    echo -e "Status:   \033[0;31mBEENDET (Skript läuft nicht mehr)\033[0m"
fi

# 2. Aktive Downloads
DOWNLOADER=""
if pgrep -x "aria2c" > /dev/null; then DOWNLOADER="aria2c"; fi
if pgrep -x "curl" > /dev/null; then DOWNLOADER="curl"; fi

if [ ! -z "$DOWNLOADER" ]; then
    echo "Netzwerk: $DOWNLOADER lädt gerade Daten herunter..."
else
    echo "Netzwerk: Keine aktiven Downloads erkannt."
fi

echo "--------------------------------------------------------"

# 3. Speicherplatz
if [ -d "$TARGET_DIR" ]; then
    FREE_SPACE=$(df -h "$TARGET_DIR" | awk 'NR==2 {print $4}')
    USED_SPACE=$(du -sh "$TARGET_DIR" 2>/dev/null | awk '{print $1}')
    echo "Speicher auf Platte: $USED_SPACE belegt / $FREE_SPACE noch frei"
else
    echo -e "Speicher: \033[0;31mFESTPLATTE NICHT GEFUNDEN!\033[0m"
fi

echo "--------------------------------------------------------"

# 4. Aktuelle Dateigrößen der ZIM-Dateien
echo "Aktueller Stand der großen Archive:"
if [ -d "$TARGET_DIR/01_zim" ]; then
    find "$TARGET_DIR/01_zim" -name "*.zim" -exec ls -lh {} + | awk '{print "  - " $9 " (" $5 ")"}'
else
    echo "  (Noch keine Archive vorhanden)"
fi

echo "--------------------------------------------------------"

# 5. Letzte Log-Einträge
LATEST_LOG=$(ls -t "$LOG_DIR"/run_v3_*.log 2>/dev/null | head -n 1)
if [ ! -z "$LATEST_LOG" ]; then
    echo "Letzte Aktion laut Log ($(basename "$LATEST_LOG")):"
    tail -n 3 "$LATEST_LOG" | sed 's/^/  /'
fi

echo "========================================================"
echo "Tipp: 'bash $SCRIPT_DIR/status.sh' zur Aktualisierung."
