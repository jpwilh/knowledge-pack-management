#!/bin/bash
# notfall_manage.sh - Zentrales Management fuer den NOTFALL_PC

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SOURCE_DIR}/core_engine.sh"

# Voraussetzungen pruefen
bash "${SOURCE_DIR}/check_requirements.sh" || exit 1

TARGET_MOUNT="${NOTFALL_PC_MOUNT}"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --all            Alles aktualisieren"
    echo "  --knowledge      Wissens-Datenbanken (ZIM) laden"
    echo "  --readers        Anzeige-Programme (Kiwix, etc.) laden"
    echo "  --software       Java, Python, NPM, Docker laden"
    echo "  --models         LLM Modelle (Ollama) laden"
    echo "  --isos           Betriebssystem-Images laden"
    exit 1
}

if [ $# -eq 0 ]; then usage; fi

# --- MODULE ---
run_knowledge() {
    log ">>> Starte Knowledge Pack Update..."
    local items_json=$(get_manifest_val ".knowledge.items")

    echo "$items_json" | jq -c '.[]' | while read -r item; do
        local url=$(echo "$item" | jq -r '.url')
        local name=$(echo "$item" | jq -r '.name')
        local path=$(echo "$item" | jq -r '.path')
        local filename=$(basename "$url")
        # Sonderbehandlung fuer Dateinamen (z.B. PDFs mit langen Namen)
        if echo "$item" | jq -e '.filename' &>/dev/null; then
            filename=$(echo "$item" | jq -r '.filename')
        fi
        robust_download "$url" "${TARGET_MOUNT}/${path}/${filename}" 1000 # Min 1MB
    done
}


run_readers() {
    log ">>> Starte Reader Update..."
    local base_path=$(get_manifest_val ".readers.base_path")
    local items_json=$(get_manifest_val ".readers.items")
    echo "$items_json" | jq -c '.[]' | while read -r item; do
        local url=$(echo "$item" | jq -r '.url')
        local fname=$(echo "$item" | jq -r '.filename')
        robust_download "$url" "${TARGET_MOUNT}/${base_path}/${fname}" 5000 # Min 5MB
    done
}

run_software() {
    log ">>> Starte Software Artifact Update..."
    # Java (Maven)
    local mvn_items=$(get_manifest_val ".software.maven.items")
    local mvn_path=$(get_manifest_val ".software.maven.base_path")
    echo "$mvn_items" | jq -r '.[]' | while read -r dep; do
        log "Maven: $dep"
        mvn dependency:get -Dartifact="$dep" -Dmaven.repo.local="${TARGET_MOUNT}/${mvn_path}" -Dtransitive=true -q
    done

    # Python (pip)
    local py_items=$(get_manifest_val ".software.python.items")
    local py_path=$(get_manifest_val ".software.python.base_path")
    mkdir -p "${TARGET_MOUNT}/${py_path}"
    echo "$py_items" | jq -r '.[]' | while read -r pkg; do
        if ! ls "${TARGET_MOUNT}/${py_path}/${pkg}"*.whl &>/dev/null; then
            log "Python: $pkg"
            pip download --dest "${TARGET_MOUNT}/${py_path}" "$pkg" -q
        fi
    done

    # NPM (Verdaccio)
    local npm_items=$(get_manifest_val ".software.npm.items")
    local npm_path=$(get_manifest_val ".software.npm.base_path")
    log "NPM: Starte Verdaccio Proxy..."
    docker stop verdaccio-proxy &>/dev/null && docker rm verdaccio-proxy &>/dev/null
    sudo chown -R 10001:10001 "${TARGET_MOUNT}/${npm_path}"
    docker run -d --name verdaccio-proxy -p 4873:4873 -v "${TARGET_MOUNT}/${npm_path}:/verdaccio/storage" verdaccio/verdaccio &>/dev/null
    sleep 10
    echo "$npm_items" | jq -r '.[]' | while read -r pkg; do
        log "NPM: $pkg"
        npm install --registry "http://localhost:4873" "$pkg" --prefix /tmp/npm_prime --no-save -q
    done
    docker stop verdaccio-proxy &>/dev/null && docker rm verdaccio-proxy &>/dev/null
    sudo chown -R $(id -u):$(id -g) "${TARGET_MOUNT}/${npm_path}"

    # Docker
    local dkr_items=$(get_manifest_val ".software.docker.items")
    local dkr_path=$(get_manifest_val ".software.docker.base_path")
    mkdir -p "${TARGET_MOUNT}/${dkr_path}"
    echo "$dkr_items" | jq -r '.[]' | while read -r img; do
        local fname=$(echo "$img" | tr ': ' '_').tar
        if [ ! -f "${TARGET_MOUNT}/${dkr_path}/${fname}" ]; then
            log "Docker: $img"
            docker pull "$img" -q && docker save "$img" -o "${TARGET_MOUNT}/${dkr_path}/${fname}"
        fi
    done
}

run_models() {
    log ">>> Starte LLM Model Update..."
    local base_path=$(get_manifest_val ".models.base_path")
    local items=$(get_manifest_val ".models.items")
    docker stop ollama-priming &>/dev/null && docker rm ollama-priming &>/dev/null
    docker run -d --name ollama-priming -v "${TARGET_MOUNT}/${base_path}:/root/.ollama/models" -p 11435:11434 ollama/ollama &>/dev/null
    sleep 10
    echo "$items" | jq -r '.[]' | while read -r model; do
        log "LLM: $model"
        docker exec ollama-priming ollama pull "$model"
    done
    docker stop ollama-priming && docker rm ollama-priming
}

run_isos() {
    log ">>> Starte ISO Image Update..."
    local base_path=$(get_manifest_val ".isos.base_path")
    local items_json=$(get_manifest_val ".isos.items")
    echo "$items_json" | jq -c '.[]' | while read -r item; do
        local url=$(echo "$item" | jq -r '.url')
        local fname=$(echo "$item" | jq -r '.filename')
        robust_download "$url" "${TARGET_MOUNT}/${base_path}/${fname}" 500000 # Min 500MB
    done
}

# --- MAIN LOOP ---

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            run_knowledge; run_readers; run_software; run_models; run_isos; shift ;;
        --knowledge) run_knowledge; shift ;;
        --readers)   run_readers; shift ;;
        --software)  run_software; shift ;;
        --models)    run_models; shift ;;
        --isos)      run_isos; shift ;;
        *) usage ;;
    esac
done

log "=== Alle gewaehlten Aufgaben abgeschlossen! ==="
