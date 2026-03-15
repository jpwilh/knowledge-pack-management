#!/bin/bash
# download_isos.sh - Lädt OS-Installationsmedien für den Notfall

TARGET_MOUNT="${NOTFALL_PC_MOUNT}"
TARGET_DIR="${TARGET_MOUNT}/isos"

echo "=== OS ISO Download Start ==="

# 0. Voraussetzungen prüfen
bash "$(dirname "$0")/check_requirements.sh" || exit 1

# Funktion für robusten Download
download_iso() {
    local name=$1
    local url=$2
    local dest=$3
    
    echo "[*] Prüfe ${name}..."
    if [ -f "$dest" ]; then
        echo "Datei existiert bereits. Prüfe auf Vollständigkeit..."
        # Wir nutzen wget -c, was nur fehlende Teile lädt
    fi
    wget -c "$url" -O "$dest"
}

# 1. Linux: Ubuntu 24.04.1 LTS (Desktop)
# Link aktualisiert auf 24.04.1
echo "[1/3] Ubuntu LTS..."
download_iso "Ubuntu 24.04.1" "https://releases.ubuntu.com/24.04.1/ubuntu-24.04.1-desktop-amd64.iso" "${TARGET_DIR}/ubuntu-24.04-desktop.iso"

# 2. Linux: SystemRescue
echo "[2/3] SystemRescue..."
download_iso "SystemRescue" "https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/11.01/systemrescue-11.01-amd64.iso/download" "${TARGET_DIR}/systemrescue-11.01.iso"

# 3. Windows
echo "[3/3] Windows Hinweis..."
echo "HINWEIS: Windows ISOs müssen manuell unter https://www.microsoft.com/software-download/windows11 geladen werden."

echo "=== Zusammenfassung ==="
ls -lh "${TARGET_DIR}"
