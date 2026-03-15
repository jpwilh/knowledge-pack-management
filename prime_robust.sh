#!/bin/bash
# prime_robust.sh - Robuste, dateibasierte Offline-Bibliothek auf dem NOTFALL_PC

# Konfiguration
MAVEN_DIR="/media/jpw/NOTFALL_PC/libraries/maven"
PYTHON_DIR="/media/jpw/NOTFALL_PC/libraries/python"
NPM_DIR="/media/jpw/NOTFALL_PC/libraries/npm"
DOCKER_DIR="/media/jpw/NOTFALL_PC/libraries/docker"

echo "=== Robust Priming Start ==="

# 0. Tool-Check
echo "[0/4] Prüfe Voraussetzungen..."
REQUIRED_TOOLS=("mvn" "pip" "docker" "npm" "git" "sudo")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "FEHLER: Folgende Programme fehlen: ${MISSING_TOOLS[*]}"
    echo "Bitte installiere diese mit: sudo apt update && sudo apt install -y maven python3-pip docker.io nodejs git"
    exit 1
fi
echo "Alle benötigten Programme sind vorhanden."

# 1. Java (Maven) - Stabile Release-Versionen von Spring Boot & Camel
echo "[1/4] Priming Java (Maven) nach ${MAVEN_DIR}..."
JAVA_DEPS=(
    "org.springframework.boot:spring-boot-starter-web:3.3.0"
    "org.springframework.boot:spring-boot-starter-data-jpa:3.3.0"
    "org.apache.camel:camel-core:4.4.0"
    "jakarta.platform:jakarta.jakartaee-api:10.0.0"
    "junit:junit:4.13.2"
)

for dep in "${JAVA_DEPS[@]}"; do
    echo "Processing Java Lib: ${dep}"
    mvn dependency:get -Dartifact="${dep}" -Dmaven.repo.local="${MAVEN_DIR}" -Dtransitive=true
done

# 2. Python (pip) - Stabile Wheels ziehen
echo "[2/4] Priming Python (pip) nach ${PYTHON_DIR}..."
PYTHON_PKGS=("django" "flask" "fastapi" "pandas" "tensorflow" "ansible" "requests")

for pkg in "${PYTHON_PKGS[@]}"; do
    echo "Downloading Python: ${pkg}"
    pip download --dest "${PYTHON_DIR}" "${pkg}"
done

# 3. NPM (Verdaccio Proxy)
echo "[3/4] Priming NPM (Verdaccio Proxy) nach ${NPM_DIR}..."
# ... (restlicher NPM Teil bleibt gleich bis zum Aufräumen)
# Container aufräumen
docker stop verdaccio-proxy &>/dev/null && docker rm verdaccio-proxy &>/dev/null
# Berechtigungen wieder auf jpw zurückgeben
sudo chown -R jpw:jpw "${NPM_DIR}"
rm -rf /tmp/npm_prime

# 4. Docker Basis-Images
echo "[4/4] Priming Docker Images nach ${DOCKER_DIR}..."
DOCKER_DIR="/media/jpw/NOTFALL_PC/libraries/docker"
sudo mkdir -p "${DOCKER_DIR}" && sudo chown jpw:jpw "${DOCKER_DIR}"

IMAGES=(
    "ubuntu:24.04"
    "alpine:latest"
    "python:3.12-slim"
    "node:22-slim"
    "openjdk:21-slim"
    "nginx:alpine"
    "postgres:16-alpine"
    "redis:7-alpine"
    "busybox"
)

for img in "${IMAGES[@]}"; do
    filename=$(echo "${img}" | tr ': ' '_').tar
    echo "Processing Docker Image: ${img} -> ${filename}"
    docker pull "${img}"
    docker save "${img}" -o "${DOCKER_DIR}/${filename}"
done

echo "=== Zusammenfassung ==="
echo "Java (Maven) Dateien: $(find ${MAVEN_DIR} -type f | wc -l)"
echo "Python Wheels: $(ls -l ${PYTHON_DIR} | wc -l)"
echo "NPM Pakete: $(ls -R ${NPM_DIR} | grep '.tgz' | wc -l)"
echo "Docker Images: $(ls -l ${DOCKER_DIR} | grep '.tar' | wc -l)"
echo "=== Robust Priming Beendet! ==="
