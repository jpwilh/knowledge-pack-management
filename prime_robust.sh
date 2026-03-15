#!/bin/bash
# prime_robust.sh - Robuste, dateibasierte Offline-Bibliothek auf dem NOTFALL_PC

# Konfiguration
TARGET_MOUNT="${NOTFALL_PC_MOUNT:-/media/jpw/NOTFALL_PC}"
MAVEN_DIR="${TARGET_MOUNT}/libraries/maven"
PYTHON_DIR="${TARGET_MOUNT}/libraries/python"
NPM_DIR="${TARGET_MOUNT}/libraries/npm"
DOCKER_DIR="${TARGET_MOUNT}/libraries/docker"

echo "=== Robust Priming Start ==="

# 0. Voraussetzungen prüfen
bash "$(dirname "$0")/check_requirements.sh" || exit 1

# 1. Java (Maven)
echo "[1/4] Priming Java (Maven)..."
JAVA_DEPS=(
    "org.springframework.boot:spring-boot-starter-web:3.3.0"
    "org.springframework.boot:spring-boot-starter-data-jpa:3.3.0"
    "org.apache.camel:camel-core:4.4.0"
    "jakarta.platform:jakarta.jakartaee-api:10.0.0"
    "junit:junit:4.13.2"
)
for dep in "${JAVA_DEPS[@]}"; do
    # Maven überspringt automatisch, wenn im lokalen Repository vorhanden
    mvn dependency:get -Dartifact="${dep}" -Dmaven.repo.local="${MAVEN_DIR}" -Dtransitive=true -q
done

# 2. Python (pip)
echo "[2/4] Priming Python (pip)..."
PYTHON_PKGS=("django" "flask" "fastapi" "pandas" "tensorflow" "ansible" "requests")
for pkg in "${PYTHON_PKGS[@]}"; do
    # Wir laden nur, wenn das Paket noch nicht als .whl vorhanden ist
    if ls "${PYTHON_DIR}/${pkg}"*.whl &>/dev/null; then
        echo "Python Paket ${pkg} bereits vorhanden. Überspringe."
    else
        pip download --dest "${PYTHON_DIR}" "${pkg}" -q
    fi
done

# 3. NPM (Verdaccio Proxy)
echo "[3/4] Priming NPM (Verdaccio Proxy)..."
NPM_PKGS=("next" "react" "vue" "tailwindcss" "lodash" "axios")
docker stop verdaccio-proxy &>/dev/null && docker rm verdaccio-proxy &>/dev/null
sudo chown -R 10001:10001 "${NPM_DIR}"
docker run -d --name verdaccio-proxy -p 4873:4873 -v "${NPM_DIR}:/verdaccio/storage" verdaccio/verdaccio &>/dev/null
sleep 10
for pkg in "${NPM_PKGS[@]}"; do
    # npm install überspringt automatisch, wenn im Verdaccio-Storage
    npm install --registry "http://localhost:4873" "${pkg}" --prefix /tmp/npm_prime --no-save -q
done
docker stop verdaccio-proxy &>/dev/null && docker rm verdaccio-proxy &>/dev/null
sudo chown -R jpw:jpw "${NPM_DIR}"
rm -rf /tmp/npm_prime

# 4. Docker Basis-Images
echo "[4/4] Priming Docker Images..."
sudo mkdir -p "${DOCKER_DIR}" && sudo chown jpw:jpw "${DOCKER_DIR}"
IMAGES=("ubuntu:24.04" "alpine:latest" "python:3.12-slim" "node:22-slim" "nginx:alpine" "postgres:16-alpine" "redis:7-alpine" "busybox")
for img in "${IMAGES[@]}"; do
    filename=$(echo "${img}" | tr ': ' '_').tar
    if [ -f "${DOCKER_DIR}/${filename}" ]; then
        echo "Docker Image ${img} bereits als .tar vorhanden. Überspringe."
    else
        docker pull "${img}" -q
        docker save "${img}" -o "${DOCKER_DIR}/${filename}"
    fi
done

echo "=== Zusammenfassung ==="
echo "Java (Maven) Dateien: $(find ${MAVEN_DIR} -type f | wc -l)"
echo "Python Wheels: $(ls -1 ${PYTHON_DIR}/*.whl 2>/dev/null | wc -l)"
echo "NPM Pakete: $(find ${NPM_DIR} -name "*.tgz" | wc -l)"
echo "Docker Images: $(ls -1 ${DOCKER_DIR}/*.tar 2>/dev/null | wc -l)"
echo "=== Robust Priming Beendet! ==="
