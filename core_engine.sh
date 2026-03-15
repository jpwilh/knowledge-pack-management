#!/bin/bash
# core_engine.sh - Zentrale Funktionen fuer Download und Validierung

log() { echo "[$(date '+%F %T')] $*"; }
error() { echo "[$(date '+%F %T')] [ERROR] $*" >&2; }

# Universelle Download-Funktion mit Validierung
# Usage: robust_download <url> <dest> <min_size_kb>
robust_download() {
    local url="$1"
    local dest="$2"
    local min_size="${3:-100}" # Default 100KB
    
    mkdir -p "$(dirname "$dest")"
    
    # Idempotenz-Pruefung
    if [[ -s "$dest" && $(du -k "$dest" | cut -f1) -ge "$min_size" ]]; then
        log "Bereits vorhanden und valide: $(basename "$dest")"
        return 0
    fi
    
    log "Lade: $url -> $dest"
    curl -L -f -C - -o "$dest" \
         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0" \
         --connect-timeout 30 --retry 3 "$url"
    
    local status=$?
    if [ $status -ne 0 ]; then
        error "Download fehlgeschlagen (Exit Code $status): $url"
        return 1
    fi
    
    # Validierung: Dateityp pruefen (kein HTML/Fehlerseite)
    local file_type=$(file -b "$dest" 2>/dev/null)
    if [[ "$file_type" == *"HTML"* || "$file_type" == *"XML"* ]]; then
        error "Validierungsfehler: Datei ist HTML/XML (wahrscheinlich Fehlerseite): $dest"
        mv "$dest" "${dest}.error"
        return 1
    fi
    
    log "Erfolgreich geladen: $(basename "$dest")"
    return 0
}

# Hilfsfunktion fuer JSON-Abfragen via jq
get_manifest_val() {
    jq -r "$1" "$(dirname "$0")/manifest.json"
}
