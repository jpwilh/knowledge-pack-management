#!/bin/bash
# check_requirements.sh - Zentraler Check für Programme und Umgebungsvariablen

# 1. Umgebungsvariablen prüfen
echo "[*] Prüfe Umgebungsvariablen..."
if [ -z "${NOTFALL_PC_MOUNT}" ]; then
    echo "FEHLER: NOTFALL_PC_MOUNT ist nicht gesetzt!"
    echo "Bitte mit 'export NOTFALL_PC_MOUNT=/dein/pfad' setzen oder in ~/.bashrc eintragen."
    exit 1
fi

if [ ! -d "${NOTFALL_PC_MOUNT}" ]; then
    echo "FEHLER: Mountpoint ${NOTFALL_PC_MOUNT} existiert nicht oder ist nicht erreichbar!"
    exit 1
fi
echo "OK: NOTFALL_PC_MOUNT = ${NOTFALL_PC_MOUNT}"

# 2. Benötigte Programme prüfen
echo "[*] Prüfe benötigte Programme..."
REQUIRED_TOOLS=("mvn" "pip" "docker" "npm" "git" "wget" "curl" "sudo" "jq" "file" "zimcheck" "pdfinfo" "isoinfo" "unzip")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

# Optionale/Spezialisierte Tools separat prüfen
if ! command -v ollama &> /dev/null; then
    echo "HINWEIS: 'ollama' fehlt (wird für LLM-Modelle benötigt)."
fi

if ! command -v kiwix-serve &> /dev/null; then
    echo "HINWEIS: 'kiwix-serve' fehlt (wird für die globale Offline-Suche benötigt)."
    echo "Installation: sudo apt install kiwix-tools"
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "FEHLER: Folgende Programme fehlen: ${MISSING_TOOLS[*]}"
    echo "Installation: sudo apt update && sudo apt install -y maven python3-pip docker.io nodejs git wget curl jq file zim-tools poppler-utils genisoimage unzip"
    exit 1
fi

echo "OK: Alle Basis-Programme vorhanden."
exit 0
