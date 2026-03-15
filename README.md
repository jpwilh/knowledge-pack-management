# Offline Knowledge & Artifact Pack (2026 Maintenance Edition)

Dieses Repository enthält eine Sammlung von Skripten zum Aufbau und zur Wartung eines autarken Offline-Systems auf Basis des **NOTFALL_PC** Konzepts. Es kombiniert globales Wissen (Wikipedia, Reader) mit einer umfangreichen Basis an Software-Entwicklungs-Artefakten (Java, Python, NPM).

## Kern-Features

### 1. Global Knowledge Pack (Wikipedia & ZIM)
*   **Skript:** `offline_knowledge_pack.sh` & `download_readers.sh`
*   **Inhalt:** Aktuelle ZIM-Dateien (Wikipedia, Wiktionary, etc.) und portable Reader für Windows/Linux.
*   **Integrität:** Automatische Validierung fehlerhafter Downloads.

### 2. Software Artifact Cache (Robust-Edition)
*   **Skript:** `prime_robust.sh`
*   **Inhalt:** Stabile Framework-Stacks für die moderne Softwareentwicklung.
*   **Struktur auf dem NOTFALL_PC (`/libraries`):**
    *   **Java (Maven):** Vollständiges lokales Repository mit Spring Boot 3.3, Camel 4.4, Jakarta EE 10.
    *   **Python (pip):** Wheels für Data Science (Pandas, TensorFlow), Web (Django, FastAPI) und Automatisierung (Ansible).
    *   **NPM:** Lokale Spiegelung von React, Vue, Next.js, Tailwind via Verdaccio-Storage.
    *   **Docker:** Gängige Basis-Images (Ubuntu, Alpine, Python, Node, etc.) als portable `.tar`-Dateien.

## Benutzung

### Voraussetzungen
*   Linux-System mit Docker (für NPM-Proxy)
*   Java/Maven & Python3 installiert (für das Priming)
*   Mountpoint `<TARGET_MOUNT>` muss existieren und beschreibbar sein.

### Installation & Priming
1.  **Status prüfen:** `bash status.sh`
2.  **Wissens-Download starten:** `bash offline_knowledge_pack.sh`
3.  **Software-Bibliothek aufbauen:** `bash prime_robust.sh`

### Offline-Nutzung
*   **Java:** `mvn install -Dmaven.repo.local=<TARGET_MOUNT>/libraries/maven`
*   **Python:** `pip install --no-index --find-links=<TARGET_MOUNT>/libraries/python <paket>`
*   **NPM:** Verdaccio mit Mount auf `<TARGET_MOUNT>/libraries/npm` starten.
*   **Docker:** `docker load -i <TARGET_MOUNT>/libraries/docker/<image_name>.tar`

## Überwachung
*   `traffic.sh`: Live-Netzwerkmonitor.
*   `watchdog.sh`: Sorgt für den automatischen Neustart des Haupt-Download-Skripts bei Verbindungsabbrüchen.

