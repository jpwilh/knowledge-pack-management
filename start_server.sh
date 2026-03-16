#!/bin/bash
# start_server.sh - Generischer, robuster Kiwix-Server Starter
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nutze den Mountpoint aus der Umgebung oder falle auf das lokale Verzeichnis zurück
BASE_DIR="${NOTFALL_PC_MOUNT:-$SOURCE_DIR}"
ZIM_DIR="${BASE_DIR}/notfall-pc/01_zim"
PORT=8080

echo "[*] Suche ZIM-Dateien in: $ZIM_DIR"

if [ ! -d "$ZIM_DIR" ]; then
    echo "FEHLER: Verzeichnis $ZIM_DIR existiert nicht!"
    exit 1
fi

# 1. Alle ZIM-Dateien finden und Basis-Validierung (Signatur)
mapfile -t VALID_FILES < <(find "$ZIM_DIR" -name "*.zim" -type f -exec sh -c 'head -c 3 "$1" | grep -q "ZIM" && echo "$1"' _ {} \;)

if [ ${#VALID_FILES[@]} -eq 0 ]; then
    echo "FEHLER: Keine validen ZIM-Dateien gefunden!"
    exit 1
fi

# 2. Iterativer Startversuch
CURRENT_LIST=("${VALID_FILES[@]}")

while [ ${#CURRENT_LIST[@]} -gt 0 ]; do
    echo "[*] Versuche Server-Start mit ${#CURRENT_LIST[@]} Dateien auf Port $PORT..."
    
    TMP_ERR=$(mktemp)
    # Start im Hintergrund, um Stabilität zu prüfen
    kiwix-serve --port=$PORT "${CURRENT_LIST[@]}" 2> "$TMP_ERR" &
    PID=$!
    
    # Warte kurz, um zu sehen ob er abstürzt (z.B. wegen Index-Fehlern)
    sleep 3
    
    if kill -0 $PID 2>/dev/null; then
        echo "------------------------------------------------"
        echo "OK: Server läuft erfolgreich auf http://localhost:$PORT"
        echo "Anzahl geladener Pakete: ${#CURRENT_LIST[@]}"
        echo "------------------------------------------------"
        rm -f "$TMP_ERR"
        wait $PID
        exit 0
    else
        # Fehleranalyse: Extrahiere Pfad der problematischen Datei aus stderr
        ERR_MSG=$(cat "$TMP_ERR")
        # Sucht nach Pfaden in einfachen Anführungszeichen (Kiwix Fehlermuster)
        BAD_FILE=$(echo "$ERR_MSG" | grep -o "/.*\.zim" | head -n 1 | tr -d "'")
        
        if [ -n "$BAD_FILE" ]; then
            echo "WARNUNG: Datei konnte nicht geladen werden: $(basename "$BAD_FILE")"
            echo "[*] Entferne Problemdatei und versuche Neustart..."
            
            # Neue Liste ohne die Problemdatei erstellen
            NEW_LIST=()
            for f in "${CURRENT_LIST[@]}"; do
                if [[ "$f" != "$BAD_FILE" ]]; then
                    NEW_LIST+=("$f")
                fi
            done
            CURRENT_LIST=("${NEW_LIST[@]}")
        else
            echo "KRITISCHER FEHLER: Server-Start unmöglich."
            cat "$TMP_ERR"
            rm -f "$TMP_ERR"
            exit 1
        fi
        rm -f "$TMP_ERR"
    fi
done

echo "FEHLER: Konnte keine der ZIM-Dateien erfolgreich bereitstellen."
exit 1
