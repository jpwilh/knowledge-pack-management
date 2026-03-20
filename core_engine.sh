#!/bin/bash
# core_engine.sh - Zentrale Funktionen mit Metadaten-Tracking und DRY-RUN Modus

# Globale Einstellungen
DRY_RUN="${DRY_RUN:-false}"
CHECK_ONLY="${CHECK_ONLY:-false}"

log() { echo "[$(date '+%F %T')] $*"; }
error() { 
    echo "[$(date '+%F %T')] [ERROR] $*" >&2
    echo "$*" >> "${SOURCE_DIR}/failed_items.log"
}

# Hilfsfunktion fuer destruktive Befehle
run_cmd() {
    local cmd="$1"
    local desc="$2"
    if [ "$DRY_RUN" == "true" ]; then
        log "[DRY-RUN] Wuerde ausfuehren: $desc"
        return 0
    else
        eval "$cmd"
        return $?
    fi
}

# Initialisierung der Fehlerliste
init_error_log() {
    rm -f "${SOURCE_DIR}/failed_items.log"
    touch "${SOURCE_DIR}/failed_items.log"
}

# Zusammenfassung ausgeben
print_summary() {
    echo ""
    echo "============================================"
    echo "       ZUSAMMENFASSUNG DER AKTUALISIERUNG"
    if [ "$DRY_RUN" == "true" ]; then echo "       (MODUS: DRY-RUN / SIMULATION)"; fi
    echo "============================================"
    if [ ! -s "${SOURCE_DIR}/failed_items.log" ]; then
        echo "ALLES OK: Alle Pakete sind auf dem aktuellen Stand."
    else
        echo "ACHTUNG: Folgende Pakete konnten nicht geladen werden:"
        echo "--------------------------------------------"
        cat "${SOURCE_DIR}/failed_items.log"
        echo "--------------------------------------------"
        echo "Bitte pruefe die URLs in der manifest.json oder deine Internetverbindung."
    fi
    echo "============================================"
}

# Metadaten verwalten
update_metadata() {
    local f="$1"
    local meta="${f}.meta.json"
    local status="${2:-}"
    local url="${3:-}"
    local duration="${4:-}"
    local size=$(stat -c%s "$f" 2>/dev/null || echo 0)
    local date=$(date '+%F %T')

    if [ "$DRY_RUN" == "true" ]; then return 0; fi

    if [ ! -f "$meta" ]; then
        echo "{ \"filename\": \"$(basename "$f")\", \"source_url\": \"$url\", \"history\": [], \"validation\": { \"status\": \"none\", \"date\": \"\" } }" > "$meta"
    fi

    # Update Historie (Download/Resume)
    if [ "$status" == "download" ] || [ "$status" == "resume" ]; then
        local entry="{\"date\": \"$date\", \"action\": \"$status\", \"position\": $size, \"duration_sec\": \"$duration\"}"
        local tmp=$(mktemp)
        jq ".history += [$entry] | .file_size = $size" "$meta" > "$tmp" && mv "$tmp" "$meta"
    fi

    # Update Validierung
    if [ "$status" == "valid" ] || [ "$status" == "invalid" ]; then
        local tmp=$(mktemp)
        jq ".validation = { \"status\": \"$status\", \"date\": \"$date\" } | .file_size = $size" "$meta" > "$tmp" && mv "$tmp" "$meta"
    fi
}

# Generische Integritaetspruefung basierend auf Dateityp
verify_file_integrity() {
    local f="$1"
    local meta="${f}.meta.json"
    local ext="${f##*.}"
    
    # Existenzpruefung
    if [[ ! -s "$f" ]]; then return 1; fi

    if [ -f "$meta" ]; then
        local meta_status=$(jq -r '.validation.status' "$meta")
        local meta_size=$(jq -r '.file_size // 0' "$meta")
        local actual_size=$(stat -c%s "$f" 2>/dev/null || echo 0)
        
        if [ "$meta_status" == "valid" ] && [ "$meta_size" -eq "$actual_size" ]; then
            return 0
        fi
    fi

    # Dry-Run Schutz: Keine intensiven Prüfungen in Simulation
    if [ "$DRY_RUN" == "true" ]; then
        log "[DRY-RUN] Wuerde Integritaetspruefung (intensiv) starten: $(basename "$f")"
        return 1
    fi

    log "Integritaetspruefung (intensiv): $(basename "$f")..."
    local result=1
    case "$ext" in
        zim)
            if command -v zimcheck &>/dev/null; then
                zimcheck -C "$f" &>/dev/null
                result=$?
            else
                log "WARNUNG: zimcheck fehlt, ueberspringe."
                result=0
            fi ;;
        pdf)
            pdfinfo "$f" &>/dev/null
            result=$? ;;
        iso)
            isoinfo -d -i "$f" &>/dev/null
            result=$? ;;
        zip|apk)
            unzip -t "$f" &>/dev/null
            result=$? ;;
        json)
            jq . "$f" &>/dev/null
            result=$? ;;
        *)
            result=0 ;;
    esac

    # Status in Meta-Daten speichern
    if [ $result -eq 0 ]; then
        update_metadata "$f" "valid"
    else
        update_metadata "$f" "invalid"
    fi
    return $result
}

# Universelle Download-Funktion mit Metadaten
robust_download() {
    local url="$1"
    local dest="$2"
    local min_size="${3:-100}"

    mkdir -p "$(dirname "$dest")"
    update_metadata "$dest" "init" "$url"

    # Schnelle Idempotenz-Pruefung via Meta-Daten
    if [[ -s "$dest" && $(du -k "$dest" | cut -f1) -ge "$min_size" ]]; then
        if verify_file_integrity "$dest"; then
            log "Bereits vorhanden und verifiziert: $(basename "$dest")"
            return 0
        else
            log "Hinweis: $(basename "$dest") ist unvollstaendig oder korrupt. Versuche Fortsetzung..."
        fi
    fi

    local action="download"
    if [ -s "$dest" ]; then action="resume"; fi

    if [ "$CHECK_ONLY" == "true" ]; then
        if [ -s "$dest" ]; then
            log "[CHECK-ONLY] Vorhandene Datei wird geprueft: $(basename "$dest")"
            verify_file_integrity "$dest"
            return $?
        else
            log "[CHECK-ONLY] Datei fehlt, Download uebersprungen: $(basename "$dest")"
            return 0
        fi
    fi

    log "Aktion: $action ($url -> $dest)"
    local start_time=$(date +%s)
    
    run_cmd "curl -L -f -C - -o \"$dest\" -H \"User-Agent: Mozilla/5.0\" --connect-timeout 30 --retry 3 \"$url\"" \
            "Download von $url nach $dest"
    
    local status=$?
    if [ "$DRY_RUN" == "true" ]; then return 0; fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $status -ne 0 ]; then
        error "Download fehlgeschlagen (Exit Code $status): $url"
        if [ $status -eq 33 ]; then
            log "Server-Range-Fehler: Loesche korrupte Datei."
            run_cmd "rm -f \"$dest\" \"${dest}.meta.json\"" "Loeschen der korrupten Datei $dest"
        fi
        return 1
    fi

    # Metadaten nach erfolgreichem Download-Segment schreiben
    update_metadata "$dest" "$action" "$url" "$duration"

    # Validierung: Dateityp pruefen
    local file_type=$(file -b "$dest" 2>/dev/null)
    if [[ "$file_type" == *"HTML"* || "$file_type" == *"XML"* ]]; then
        error "Validierungsfehler: Datei ist HTML/XML (Server-Fehler): $dest"
        run_cmd "rm -f \"$dest\" \"${dest}.meta.json\"" "Loeschen der Fehlerseite $dest"
        return 1
    fi

    # Abschluss-Integritaetspruefung
    log "Abschluss-Verifizierung..."
    if ! verify_file_integrity "$dest"; then
        error "Integritaetsfehler nach Download: $dest"
        run_cmd "rm -f \"$dest\" \"${dest}.meta.json\"" "Loeschen der korrupten Datei $dest"
        return 1
    fi

    log "Erfolgreich geladen und verifiziert: $(basename "$dest")"
    return 0
}

get_manifest_val() {
    jq -r "$1" "$(dirname "$0")/manifest.json"
}
