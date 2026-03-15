# Offline Knowledge & Artifact Pack (2026 Modular Edition)

Zentrales Management-System für den **NOTFALL_PC**. Dieses Repository nutzt eine modulare Architektur zur Sicherung von globalem Wissen, Software-Artefakten, Betriebssystemen und KI-Modellen.

## Kern-Komponenten
*   **`manifest.json`**: Zentrale Liste aller Quellen und Zielpfade.
*   **`notfall_manage.sh`**: Einstiegspunkt für alle Update-Vorgänge.
*   **`core_engine.sh`**: Robuste Download- und Validierungs-Logik.

## Benutzung

### Voraussetzungen
*   Linux-System mit Docker, Java/Maven, Python3, `jq` und `curl`.
*   Umgebungsvariable `NOTFALL_PC_MOUNT` muss gesetzt sein.

### Update-Vorgänge
Führe das Management-Skript mit dem gewünschten Parameter aus:

*   **Alles aktualisieren:** `./notfall_manage.sh --all`
*   **Wissen (Wikipedia):** `./notfall_manage.sh --knowledge`
*   **Software (Maven/Pip/NPM/Docker):** `./notfall_manage.sh --software`
*   **KI Modelle (LLMs):** `./notfall_manage.sh --models`
*   **Betriebssysteme (ISOs):** `./notfall_manage.sh --isos`

## Jährliche Wartung
Um das System aktuell zu halten, sollte einmal pro Jahr folgende Routine durchgeführt werden:
1.  **`manifest.json` prüfen:** URLs für ZIM-Dateien und ISOs auf Aktualität prüfen.
2.  **Versionen anpassen:** Stabile Framework-Versionen (z.B. Spring Boot) im JSON hochsetzen.
3.  **Bereinigung:** Veraltete Großdateien (ISOs/ZIMs) auf dem `NOTFALL_PC` manuell löschen.
4.  **Lauf:** `./notfall_manage.sh --all` ausführen.

---
*Status März 2026 - Modularisiert für maximale Zuverlässigkeit.*
