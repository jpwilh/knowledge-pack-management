# Offline Knowledge & Artifact Pack (2026 Maintenance Edition)

Dieses Repository enthält eine Sammlung von Skripten zum Aufbau und zur Wartung eines autarken Offline-Systems auf Basis des **NOTFALL_PC** Konzepts. Es kombiniert globales Wissen (Wikipedia, Reader) mit einer umfangreichen Basis an Software-Entwicklungs-Artefakten (Java, Python, NPM, Docker), OS-Installationsmedien und lokalen KI-Modellen (LLMs).

## Kern-Features

### 1. Global Knowledge Pack (Wikipedia & ZIM)
*   **Skript:** `offline_knowledge_pack.sh` & `download_readers.sh`
*   **Inhalt:** Aktuelle ZIM-Dateien (Wikipedia, StackOverflow, Wiktionary, etc.) und portable Reader.

### 2. Software Artifact Cache (Robust-Edition)
*   **Skript:** `prime_robust.sh`
*   **Inhalt:** Stabile Framework-Stacks (Java/Maven, Python/pip, NPM, Docker).

### 3. OS Installationsmedien
*   **Skript:** `download_isos.sh`
*   **Inhalt:** Ubuntu 24.04 LTS, SystemRescue und Anleitungen für Windows 11.

### 4. Lokale KI (LLMs)
*   **Skript:** `download_models.sh`
*   **Inhalt:** Leistungsstarke Modelle für Chat (Llama 3.1), Programmierung (DeepSeek) und Vision (Llava) via Ollama.

## Benutzung

### Voraussetzungen
*   Linux-System mit Docker (für NPM-Proxy)
*   Java/Maven, Python3 & Ollama installiert.
*   Mountpoint `<TARGET_MOUNT>` muss existieren und beschreibbar sein.

### Installation & Priming
1.  **Status prüfen:** `bash status.sh`
2.  **Wissens-Download starten:** `bash offline_knowledge_pack.sh`
3.  **Software-Bibliothek aufbauen:** `bash prime_robust.sh`
4.  **OS-Images laden:** `bash download_isos.sh`
5.  **KI-Modelle laden:** `bash download_models.sh`

### Offline-Nutzung
*   **Java/Python/NPM/Docker:** Siehe Dokumentation in `README.md`.
*   **KI/LLMs:** `export OLLAMA_MODELS=<TARGET_MOUNT>/models && ollama serve`

## Überwachung
*   `traffic.sh`: Live-Netzwerkmonitor.
*   `watchdog.sh`: Automatischer Neustart bei Verbindungsabbrüchen.

---
*Status März 2026 - Gepflegt für den autarken Notfallbetrieb.*
