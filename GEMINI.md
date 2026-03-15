# Knowledge Pack & Artifact Management Mandates

## Projekt-Fokus
Aufbau und Wartung eines 100% autarken Offline-Systems (NOTFALL_PC) mit Wissen und Software-Entwicklungsgrundlagen.

## Haupt-Mandate

### 1. Robustheit (Knowledge)
*   **Validierung:** Das Skript `offline_knowledge_pack.sh` muss Downloads gegen fehlerhafte HTML-Seiten (404/Login-Seiten) validieren und diese ggf. löschen.
*   **Kontinuität:** Der `watchdog.sh` sorgt für einen unterbrechungsfreien Download-Prozess.

### 2. Datenintegrität (Software Artifacts)
*   **Keine Abhängigkeit von Diensten:** Bevorzuge die "Robust-Lösung" (`prime_robust.sh`), die Artefakte als echte Dateien im Dateisystem ablegt, anstatt sie in Container-internen Datenbanken zu verstecken.
*   **Stabilität:** Nur getaggte, stabile Versionen (Releases) laden. Snapshots vermeiden, da diese offline nicht reproduzierbar sind.
*   **Transparenz:** Die Ordnerstruktur auf `/media/jpw/NOTFALL_PC/libraries` muss menschenlesbar und ohne Spezialtools nutzbar sein.

### 3. Ziel-Hardware
*   Primäres Ziel ist immer `/media/jpw/NOTFALL_PC`. Alle Pfade müssen relativ zu diesem Mountpoint konfigurierbar oder fest verdrahtet sein.

## Benutzung (CLI)
1.  `bash status.sh` - Gesamtüberblick.
2.  `bash prime_robust.sh` - Software-Cache befüllen.
3.  `bash offline_knowledge_pack.sh` - Wissens-Cache befüllen.
