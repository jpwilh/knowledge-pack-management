#!/bin/bash
# core_engine.sh - Zentrale Funktionen fuer Download und Validierung

log() { echo "[$(date '+%F %T')] $*"; }
error() { 
    echo "[$(date '+%F %T')] [ERROR] $*" >&2
    echo "$*" >> "${SOURCE_DIR}/failed_items.log"
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

# Generische Integritaetspruefung basierend auf Dateityp
verify_file_integrity() {
    local f="$1"
    local ext="${f##*.}"
    local filename=$(basename "$f")
    
    # Existenzpruefung
    if [[ ! -s "$f" ]]; then return 1; fi

    case "$ext" in
        zim)
            if command -v zimcheck &>/dev/null; then
                # zimcheck -C prueft die interne Pruefsumme des ZIM-Archivs
                zimcheck -C "$f" &>/dev/null
                return $?
            else
                log "WARNUNG: zimcheck nicht installiert, ueberspringe Validierung."
                return 0
            fi ;;
        pdf)
            if command -v pdfinfo &>/dev/null; then
                pdfinfo "$f" &>/dev/null
                return $?
            else
                log "WARNUNG: pdfinfo nicht installiert, ueberspringe Validierung."
                return 0
            fi ;;
        iso)
            if command -v isoinfo &>/dev/null; then
                isoinfo -d -i "$f" &>/dev/null
                return $?
            else
                log "WARNUNG: isoinfo nicht installiert, ueberspringe Validierung."
                return 0
            fi ;;
        zip|apk)
            if command -v unzip &>/dev/null; then
                unzip -t "$f" &>/dev/null
                return $?
            else
                log "WARNUNG: unzip nicht installiert, ueberspringe Validierung."
                return 0
            fi ;;
        json)
            if command -v jq &>/dev/null; then
                jq . "$f" &>/dev/null
                return $?
            else
                log "WARNUNG: jq nicht installiert, ueberspringe Validierung."
                return 0
            fi ;;
        *)
            # Fallback für unbekannte Typen: Nur Existenzprüfung
            return 0 ;;
    esac
}

# Universelle Download-Funktion mit Validierung
# Usage: robust_download <url> <dest> <min_size_kb>
robust_download() {
    local url="$1"
    local dest="$2"
    local min_size="${3:-100}" # Default 100KB

    mkdir -p "$(dirname "$dest")"

    # Idempotenz-Pruefung mit generischer Validierung
    if [[ -s "$dest" && $(du -k "$dest" | cut -f1) -ge "$min_size" ]]; then
        if verify_file_integrity "$dest"; then
            log "Bereits vorhanden und valide: $(basename "$dest")"
            return 0
        else
            log "Hinweis: $(basename "$dest") ist unvollstaendig oder korrupt. Versuche Fortsetzung..."
        fi
    fi

    log "Lade/Setze fort: $url -> $dest"
    curl -L -f -C - -o "$dest" \
         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0" \
         --connect-timeout 30 --retry 3 "$url"

    local status=$?
    if [ $status -ne 0 ]; then
        error "Download fehlgeschlagen (Exit Code $status): $url"
        # Fehler 33: Range not satisfiable (Lokal groesser als Server) -> Neuanfang
        if [ $status -eq 33 ]; then
            log "Server meldet Range-Fehler. Loesche korrupte Datei..."
            rm -f "$dest"
        fi
        return 1
    fi

    # Validierung: Dateityp pruefen (Kein HTML-Error)
    local file_type=$(file -b "$dest" 2>/dev/null)
    if [[ "$file_type" == *"HTML"* || "$file_type" == *"XML"* ]]; then
        error "Validierungsfehler: Datei ist HTML/XML (Server-Fehlerseite): $dest"
        rm -f "$dest"
        return 1
    fi

    # Abschluss-Integritaetspruefung
    log "Verifiziere $(basename "$dest")..."
    if ! verify_file_integrity "$dest"; then
        error "Integritaetsfehler nach Download: $dest"
        rm -f "$dest"
        return 1
    fi

    log "Erfolgreich geladen und verifiziert: $(basename "$dest")"
    return 0
}

# Hilfsfunktion fuer JSON-Abfragen via jq
get_manifest_val() {
    jq -r "$1" "$(dirname "$0")/manifest.json"
}
