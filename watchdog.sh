#!/usr/bin/env bash
# Watchdog for offline_knowledge_pack_v3_de.sh

SCRIPT_DIR="/home/jpw/knowledge-pack-management"
LOG_FILE="/home/jpw/notfall_download_cron.log"

while true; do
    if ! pgrep -f "offline_knowledge_pack_v3_de.sh" > /dev/null; then
        echo "[$(date)] Skript beendet oder nicht gestartet. Starte neu..." >> "$LOG_FILE"
        # Start the script from the new location
        nohup bash "$SCRIPT_DIR/offline_knowledge_pack_v3_de.sh" >> "$LOG_FILE" 2>&1 &
    fi
    sleep 300 # Alle 5 Minuten prüfen
done
