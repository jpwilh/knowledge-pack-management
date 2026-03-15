# Offline Knowledge & Artifact Pack (2026 Maintenance Edition)

Dieses Repository enthält eine Sammlung von Skripten zum Aufbau und zur Wartung eines autarken Offline-Systems auf Basis des **NOTFALL_PC** Konzepts. Es kombiniert globales Wissen (Wikipedia, Reader) mit einer umfangreichen Basis an Software-Entwicklungs-Artefakten (Java, Python, NPM, Docker) und OS-Installationsmedien.

## Kern-Features

### 1. Global Knowledge Pack (Wikipedia & ZIM)
*   **Skript:** `offline_knowledge_pack.sh` & `download_readers.sh`
*   **Inhalt:** Aktuelle ZIM-Dateien (Wikipedia, Wiktionary, etc.) und portable Reader für Windows/Linux.

### 2. Software Artifact Cache (Robust-Edition)
*   **Skript:** `prime_robust.sh`
*   **Inhalt:** Stabile Framework-Stacks für die moderne Softwareentwicklung.
    *   **Java (Maven):** Vollständiges lokales Repository mit Spring Boot, Camel, Jakarta EE.
    *   **Python (pip):** Wheels für Data Science, Web und Automatisierung.
    *   **NPM:** Lokale Spiegelung via Verdaccio-Storage.
    *   **Docker:** Gängige Basis-Images als portable `.tar`-Dateien.

### 3. OS Installationsmedien
*   **Skript:** `download_isos.sh`
*   **Inhalt:** Ubuntu 24.04 LTS, SystemRescue und Anleitungen für Windows 11.

## Benutzung

### Voraussetzungen
*   Linux-System mit Docker (für NPM-Proxy)
*   Java/Maven & Python3 installiert (für das Priming)
*   Mountpoint `<TARGET_MOUNT>` muss existieren und beschreibbar sein.

### Installation & Priming
1.  **Status prüfen:** `bash status.sh`
2.  **Wissens-Download starten:** `bash offline_knowledge_pack.sh`
3.  **Software-Bibliothek aufbauen:** `bash prime_robust.sh`
4.  **OS-Images laden:** `bash download_isos.sh`

### Offline-Nutzung
*   **Java:** `mvn install -Dmaven.repo.local=<TARGET_MOUNT>/libraries/maven`
*   **Python:** `pip install --no-index --find-links=<TARGET_MOUNT>/libraries/python <paket>`
*   **NPM:** Verdaccio mit Mount auf `<TARGET_MOUNT>/libraries/npm` starten.
*   **Docker:** `docker load -i <TARGET_MOUNT>/libraries/docker/<image_name>.tar`
*   **OS-Installation:** ISOs unter `<TARGET_MOUNT>/isos/` auf USB-Stick flashen.

## Überwachung
*   `traffic.sh`: Live-Netzwerkmonitor.
*   `watchdog.sh`: Automatischer Neustart bei Verbindungsabbrüchen.

---
*Status März 2026 - Gepflegt für den autarken Notfallbetrieb.*
