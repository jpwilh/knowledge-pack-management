#!/usr/bin/env bash
# Watchdog for offline_knowledge_pack.sh

SCRIPT_DIR="/home/jpw/knowledge-pack-management"
LOG_FILE="/home/jpw/notfall_download_cron.log"

while true; do
    if ! pgrep -f "offline_knowledge_pack.sh" > /dev/null; then
        echo "[$(date)] Skript beendet oder nicht gestartet. Starte neu..." >> "$LOG_FILE"
        # Start the script from the new location
        nohup bash "$SCRIPT_DIR/offline_knowledge_pack.sh" >> "$LOG_FILE" 2>&1 &
    fi
    sleep 300 # Alle 5 Minuten prüfen
done
