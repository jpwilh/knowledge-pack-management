#!/bin/bash
# download_models.sh - Portabler Download von LLM-Modellen via Docker

TARGET_MOUNT="${NOTFALL_PC_MOUNT}"
MODEL_DIR="${TARGET_MOUNT}/models"

echo "=== LLM Model Download (Portable Docker Edition) ==="

# 0. Voraussetzungen pruefen
bash "$(dirname "$0")/check_requirements.sh" || exit 1

mkdir -p "${MODEL_DIR}"

# 1. Ollama-Container temporaer starten
# Wir nutzen einen anderen Port (11435), um Konflikte mit lokalem Ollama zu vermeiden
echo "[*] Starte temporaeren Ollama-Container..."
docker stop ollama-priming &>/dev/null && docker rm ollama-priming &>/dev/null
docker run -d --name ollama-priming \
  -v "${MODEL_DIR}:/root/.ollama" \
  -p 11435:11434 \
  ollama/ollama

# Kurze Pause bis Ollama bereit ist
sleep 10

# 2. Modelle ziehen
MODELS=("llama3.1" "deepseek-coder-v2:16b-lite-instruct-q4_K_M" "nomic-embed-text" "llava")

for model in "${MODELS[@]}"; do
    echo "[*] Ziehe Modell: ${model}..."
    docker exec ollama-priming ollama pull "${model}"
done

# 3. Cleanup
echo "[*] Raeume auf..."
docker stop ollama-priming && docker rm ollama-priming

echo "=== Zusammenfassung ==="
echo "Modelle gespeichert in: ${MODEL_DIR}"
echo "Anzahl Blobs: $(ls -1 ${MODEL_DIR}/models/blobs 2>/dev/null | wc -l)"
echo "=== LLM Priming Beendet! ==="
