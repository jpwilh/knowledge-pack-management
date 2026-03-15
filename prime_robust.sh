#!/bin/bash
# prime_robust.sh - Robuste, dateibasierte Offline-Bibliothek auf dem NOTFALL_PC

# Konfiguration
MAVEN_DIR="/media/jpw/NOTFALL_PC/libraries/maven"
PYTHON_DIR="/media/jpw/NOTFALL_PC/libraries/python"
NPM_DIR="/media/jpw/NOTFALL_PC/libraries/npm"

echo "=== Robust Priming Start ==="

# 1. Java (Maven) - Stabile Release-Versionen von Spring Boot & Camel
echo "[1/3] Priming Java (Maven) nach ${MAVEN_DIR}..."
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
echo "[2/3] Priming Python (pip) nach ${PYTHON_DIR}..."
PYTHON_PKGS=("django" "flask" "fastapi" "pandas" "tensorflow" "ansible" "requests")

for pkg in "${PYTHON_PKGS[@]}"; do
    echo "Downloading Python: ${pkg}"
    pip download --dest "${PYTHON_DIR}" "${pkg}"
done

# 3. NPM (Verdaccio Proxy)
echo "[3/3] Priming NPM (Verdaccio Proxy) nach ${NPM_DIR}..."
NPM_PKGS=("next" "react" "vue" "tailwindcss" "lodash" "axios")

# Alten Container löschen falls vorhanden
docker stop verdaccio-proxy &>/dev/null && docker rm verdaccio-proxy &>/dev/null

# Berechtigungen für Verdaccio-User im Container setzen (UID 10001)
sudo chown -R 10001:10001 "${NPM_DIR}"

# Verdaccio Container starten
docker run -d --name verdaccio-proxy \
  -p 4873:4873 \
  -v "${NPM_DIR}:/verdaccio/storage" \
  verdaccio/verdaccio

# Längere Pause und Health-Check
echo "Warte auf Verdaccio..."
sleep 15

for pkg in "${NPM_PKGS[@]}"; do
    echo "Installing NPM through Proxy: ${pkg}"
    npm install --registry "http://localhost:4873" "${pkg}" --prefix /tmp/npm_prime --no-save
done

# Container aufräumen
docker stop verdaccio-proxy && docker rm verdaccio-proxy
# Berechtigungen wieder auf jpw zurückgeben
sudo chown -R jpw:jpw "${NPM_DIR}"
rm -rf /tmp/npm_prime

echo "=== Zusammenfassung ==="
echo "Java (Maven) Dateien: $(find ${MAVEN_DIR} -type f | wc -l)"
echo "Python Wheels: $(ls -l ${PYTHON_DIR} | wc -l)"
echo "NPM Pakete: $(ls -R ${NPM_DIR} | grep '.tgz' | wc -l)"
echo "=== Robust Priming Beendet! ==="
