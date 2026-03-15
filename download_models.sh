#!/bin/bash
# download_models.sh - Lädt LLM-Modelle für den Offline-Betrieb via Ollama

TARGET_MOUNT="${NOTFALL_PC_MOUNT:-/media/jpw/NOTFALL_PC}"
MODEL_DIR="${TARGET_MOUNT}/models"

echo "=== LLM Model Download Start ==="

# 0. Voraussetzungen prüfen
bash "$(dirname "$0")/check_requirements.sh" || exit 1

# Prüfen ob Ollama installiert ist
if ! command -v ollama &> /dev/null; then
    echo "Ollama nicht gefunden. Installiere Ollama (benötigt Internet)..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Ollama anweisen, den NOTFALL_PC als Speicherort zu nutzen
export OLLAMA_MODELS="${MODEL_DIR}"

echo "[1/4] Lade Llama 3.1 8B (General Chat)..."
ollama pull llama3.1

echo "[2/4] Lade DeepSeek-Coder-V2-Lite (Programming)..."
ollama pull deepseek-coder-v2:16b-lite-instruct-q4_K_M

echo "[3/4] Lade Nomic-Embed-Text (Embedding)..."
ollama pull nomic-embed-text

echo "[4/4] Lade Llava (Vision/Bilder)..."
ollama pull llava

echo "=== Zusammenfassung ==="
ls -lh "${MODEL_DIR}"
echo "LLM Modelle sind nun unter ${MODEL_DIR} gesichert."
echo "Im Offline-Fall starte Ollama mit: export OLLAMA_MODELS=${MODEL_DIR} && ollama serve"
