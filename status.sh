#!/bin/bash
# status.sh - Gesamtüberblick über den NOTFALL_PC Status

MOUNT="${NOTFALL_PC_MOUNT}"

echo "=== NOTFALL_PC System Status ==="
if mountpoint -q "$MOUNT"; then
    echo "Laufwerk: Gemountet ($MOUNT)"
    df -h "$MOUNT" | tail -n 1
else
    echo "FEHLER: Laufwerk $MOUNT nicht gemountet!"
fi

echo ""
echo "=== Knowledge Packs (ZIM) ==="
if [ -d "$MOUNT/notfall-pc/01_zim" ]; then
    find "$MOUNT/notfall-pc/01_zim" -name "*.zim" -exec ls -lh {} + | awk '{print $5, $9}'
else
    echo "ZIM Verzeichnis fehlt."
fi

echo ""
echo "=== Software Artifacts ==="
[ -d "$MOUNT/libraries/maven" ] && echo "Java (Maven): $(find $MOUNT/libraries/maven -type f | wc -l) Dateien" || echo "Java (Maven): Fehlt"
[ -d "$MOUNT/libraries/python" ] && echo "Python (pip): $(ls -1 $MOUNT/libraries/python/*.whl 2>/dev/null | wc -l) Wheels" || echo "Python (pip): Fehlt"
[ -d "$MOUNT/libraries/npm" ] && echo "NPM (Proxy Storage): $(find $MOUNT/libraries/npm -name "*.tgz" | wc -l) Pakete" || echo "NPM: Fehlt"
[ -d "$MOUNT/libraries/docker" ] && echo "Docker Images: $(ls -1 $MOUNT/libraries/docker/*.tar 2>/dev/null | wc -l) Images" || echo "Docker: Fehlt"

echo ""
echo "=== Lokale KI (LLMs) ==="
# Wir pruefen sowohl den Symlink als auch den physischen Pfad
if [ -d "$MOUNT/models/blobs" ]; then
    echo "Modelle auf NOTFALL_PC: $(ls -1 $MOUNT/models/blobs | wc -l) Blobs"
    du -sh "$MOUNT/models"
    # Falls der Dienst laeuft, zeigen wir die Namen an
    if command -v ollama &> /dev/null; then
        ollama list 2>/dev/null | grep -v "NAME" || echo "Ollama Dienst antwortet gerade nicht."
    fi
else
    echo "LLM Modelle fehlen auf dem NOTFALL_PC."
fi

echo ""
echo "=== OS ISOs ==="
if [ -d "$MOUNT/isos" ]; then
    ls -lh "$MOUNT/isos" | grep ".iso" || echo "Keine ISOs gefunden."
else
    echo "ISO Verzeichnis fehlt."
fi

echo ""
echo "=== Netzwerk Traffic ==="
ip -s link show | grep -A 1 "RX: bytes" | tail -n 1
