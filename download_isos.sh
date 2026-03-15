#!/bin/bash
# download_isos.sh - Lädt OS-Installationsmedien für den Notfall

TARGET_DIR="/media/jpw/NOTFALL_PC/isos"
mkdir -p "${TARGET_DIR}"

echo "=== OS ISO Download Start ==="

# 1. Linux: Ubuntu 24.04 LTS (Desktop)
echo "[1/3] Lade Ubuntu 24.04 LTS Desktop..."
# Wir nutzen -c für Resume-Support bei großen Dateien
wget -c "https://releases.ubuntu.com/24.04/ubuntu-24.04.1-desktop-amd64.iso" -O "${TARGET_DIR}/ubuntu-24.04-desktop.iso"

# 2. Linux: SystemRescue (Essentiell für Reparaturen)
echo "[2/3] Lade SystemRescue ISO..."
wget -c "https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/11.01/systemrescue-11.01-amd64.iso/download" -O "${TARGET_DIR}/systemrescue-11.01.iso"

# 3. Windows: Windows 11
echo "[3/3] Windows 11 Information..."
echo "HINWEIS: Microsoft erlaubt keine dauerhaften direkten Download-Links."
echo "Bitte lade die aktuelle Windows 11 ISO manuell herunter und speichere sie in:"
echo "${TARGET_DIR}/windows11.iso"
echo "Link: https://www.microsoft.com/software-download/windows11"

echo "=== Zusammenfassung ==="
ls -lh "${TARGET_DIR}"
echo "ISO-Download Phase beendet."
