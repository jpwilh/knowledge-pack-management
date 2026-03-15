# Knowledge Pack Management

## Projekt-Überblick
Sammlung von Skripten zum Herunterladen, Überwachen und Verwalten des **Offline Knowledge Pack v3 (2026 Maintenance Edition)**.

## Dateistruktur
- `offline_knowledge_pack.sh`: Das Haupt-Download-Skript (korrigierte 2026 URLs).
- `status.sh`: Dashboard zur Überwachung von Speicherplatz und Download-Status.
- `traffic.sh`: Live-Netzwerkmonitor.
- `watchdog.sh`: Automatische Neustart-Überwachung für das Hauptskript.
- `download_readers*.sh`: Helfer-Skripte zum Beziehen von PDF/ZIM Readern.

## Haupt-Mandate
- **Robustheit**: Das Hauptskript validiert Downloads (löscht/umbenennt fehlerhafte HTML-Seiten).
- **Integrität**: Alle Skripte nutzen `/media/jpw/NOTFALL_PC` als primäres Ziel.
- **Wartung**: URLs müssen bei 404-Fehlern manuell in `offline_knowledge_pack.sh` aktualisiert werden.

## Benutzung
1. **Status prüfen**: `bash status.sh`
2. **Download starten**: `bash offline_knowledge_pack.sh`
3. **Automatische Überwachung**: `nohup bash watchdog.sh &`
