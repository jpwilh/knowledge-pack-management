#!/usr/bin/env bash
set -uo pipefail

# Offline knowledge pack bootstrapper v3
# - re-runnable
# - resumes partial downloads where possible
# - skips existing files
# - logs failures, keeps going
# - supports fallback URLs for unstable sources
# - removes empty/obviously bad downloads on failure
#
# Usage:
#   bash offline_knowledge_pack_v3.sh [target_dir]
#
# Optional env flags:
#   INCLUDE_DE_WIKI=1
#   INCLUDE_WIKIHOW=1
#   ONLY_PDFS=1
#   ONLY_ZIMS=1
#   DRY_RUN=1
#   MAX_RETRIES=2

TARGET_DIR="${1:-$PWD/notfall-pc}"
DRY_RUN="${DRY_RUN:-0}"
INCLUDE_DE_WIKI="${INCLUDE_DE_WIKI:-0}"
INCLUDE_WIKIHOW="${INCLUDE_WIKIHOW:-0}"
ONLY_PDFS="${ONLY_PDFS:-0}"
ONLY_ZIMS="${ONLY_ZIMS:-0}"
MAX_RETRIES="${MAX_RETRIES:-2}"

FAILED_ITEMS=0
SKIPPED_ITEMS=0
DONE_ITEMS=0

have() { command -v "$1" >/dev/null 2>&1; }

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err() { printf '[ERR] %s\n' "$*" >&2; }

need_cmd() {
  local missing=0
  for c in "$@"; do
    if ! have "$c"; then
      warn "Fehlt: $c"
      missing=1
    fi
  done
  if (( missing != 0 )); then
    err "Bitte fehlende Programme installieren."
    exit 1
  fi
}

init_logs() {
  mkdir -p "$TARGET_DIR/99_meta"
  RUN_TS="$(date '+%Y%m%d_%H%M%S')"
  FAILED_LOG="$TARGET_DIR/99_meta/failed_items.log"
  RUN_LOG="$TARGET_DIR/99_meta/run_${RUN_TS}.log"
  touch "$FAILED_LOG" "$RUN_LOG"
}

record_failed() {
  local kind="$1"
  local source="$2"
  local dest="$3"
  printf '%s\t%s\t%s\t%s\n' "$(date '+%F %T')" "$kind" "$source" "$dest" "FAILED" >> "$FAILED_LOG"
  printf '%s\t%s\t%s\t%s\n' "$(date '+%F %T')" "$kind" "$source" "$dest" "FAILED" >> "$RUN_LOG"
  FAILED_ITEMS=$((FAILED_ITEMS + 1))
}

record_done() {
  local kind="$1"
  local source="$2"
  local dest="$3"
  printf '%s\t%s\t%s\t%s\n' "$(date '+%F %T')" "$kind" "$source" "$dest" "OK" >> "$RUN_LOG"
  DONE_ITEMS=$((DONE_ITEMS + 1))
}

record_skipped() {
  local kind="$1"
  local source="$2"
  local dest="$3"
  printf '%s\t%s\t%s\t%s\n' "$(date '+%F %T')" "$kind" "$source" "$dest" "SKIPPED" >> "$RUN_LOG"
  SKIPPED_ITEMS=$((SKIPPED_ITEMS + 1))
}

cleanup_bad_file() {
  local dest="$1"
  if [[ -f "$dest" && ! -s "$dest" ]]; then
    rm -f "$dest"
    return
  fi

  if [[ -f "$dest" ]]; then
    local size
    size="$(wc -c < "$dest" 2>/dev/null || echo 0)"
    if [[ "$size" -lt 1024 ]]; then
      if grep -a -qiE '<html|<!doctype html|not found|404' "$dest" 2>/dev/null; then
        rm -f "$dest"
      fi
    fi
  fi
}

probe_url() {
  local url="$1"

  if (( DRY_RUN )); then
    return 0
  fi

  if have curl; then
    curl -L --silent --fail --range 0-0 -o /dev/null "$url"
    return $?
  fi

  if have wget; then
    wget --spider -q "$url"
    return $?
  fi

  return 0
}

download_once() {
  local url="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if have aria2c; then
    aria2c \
      --continue=true \
      --max-connection-per-server=8 \
      --split=8 \
      --min-split-size=1M \
      --summary-interval=10 \
      --dir="$(dirname "$dest")" \
      --out="$(basename "$dest")" \
      "$url"
    return $?
  fi

  if have wget; then
    wget -c --content-on-error=off -O "$dest" "$url"
    return $?
  fi

  curl -L --fail --retry 2 --retry-delay 3 -C - -o "$dest" "$url"
}

download() {
  local url="$1"
  local dest="$2"
  local kind="${3:-file}"

  mkdir -p "$(dirname "$dest")"

  if [[ -s "$dest" ]]; then
    log "Schon vorhanden, überspringe: $dest"
    record_skipped "$kind" "$url" "$dest"
    return 0
  fi

  if (( DRY_RUN )); then
    printf 'DRY  %s -> %s\n' "$url" "$dest"
    return 0
  fi

  local attempt=1
  while (( attempt <= MAX_RETRIES )); do
    log "Lade herunter (Versuch $attempt/$MAX_RETRIES): $url"

    if ! probe_url "$url"; then
      warn "URL nicht erreichbar: $url"
      attempt=$((attempt + 1))
      sleep 1
      continue
    fi

    if download_once "$url" "$dest"; then
      cleanup_bad_file "$dest"
      if [[ -s "$dest" ]]; then
        record_done "$kind" "$url" "$dest"
        return 0
      fi
      warn "Datei leer oder ungültig nach Download: $url"
    else
      warn "Download fehlgeschlagen: $url"
    fi

    cleanup_bad_file "$dest"
    attempt=$((attempt + 1))
    sleep 1
  done

  record_failed "$kind" "$url" "$dest"
  return 1
}

try_download_any() {
  local dest="$1"
  local kind="$2"
  shift 2

  if [[ -s "$dest" ]]; then
    log "Schon vorhanden, überspringe: $dest"
    record_skipped "$kind" "already-present" "$dest"
    return 0
  fi

  local url
  for url in "$@"; do
    log "Fallback-Kandidat: $url"
    if download "$url" "$dest" "$kind"; then
      return 0
    fi
  done

  record_failed "$kind" "all-fallbacks-failed" "$dest"
  return 1
}

clone_or_pull() {
  local repo="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    if (( DRY_RUN )); then
      printf 'DRY  git -C %s pull --ff-only\n' "$dest"
      return 0
    fi
    log "Aktualisiere Repo: $dest"
    if git -C "$dest" pull --ff-only; then
      record_done "git-pull" "$repo" "$dest"
      return 0
    fi
    warn "git pull fehlgeschlagen: $dest"
    record_failed "git-pull" "$repo" "$dest"
    return 1
  fi

  if [[ -d "$dest" && ! -d "$dest/.git" ]]; then
    warn "Ordner existiert ohne .git, überspringe: $dest"
    record_skipped "git-clone" "$repo" "$dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if (( DRY_RUN )); then
    printf 'DRY  git clone --depth 1 %s %s\n' "$repo" "$dest"
    return 0
  fi

  log "Klonen: $repo"
  if git clone --depth 1 "$repo" "$dest"; then
    record_done "git-clone" "$repo" "$dest"
    return 0
  fi

  warn "git clone fehlgeschlagen: $repo"
  record_failed "git-clone" "$repo" "$dest"
  return 1
}

write_readmes() {
  mkdir -p "$TARGET_DIR/00_reader"
  cat > "$TARGET_DIR/README.txt" <<'EOF'
Offline-Wissenspaket

Ordner:
- 00_reader/         Hinweise zum Lesen/Benutzen
- 01_zim/            Große Offline-Wissensarchive für Kiwix
- 02_medizin/        Praktische Medizin- und Gesundheitsliteratur
- 03_landwirtschaft/ Landwirtschaft, Bewässerung, Lagerung, Verarbeitung
- 04_technik/        Freie Technik-/Maschinenbau-/Elektronikquellen
- 05_repos/          Geklonten Open-Source-Projekten / Dokumentation
- 99_meta/           Logdateien und Manifeste

Wichtige Hinweise:
- ZIM-Dateien mit Kiwix öffnen.
- Vor dem finalen Offline-Einsatz: alles einmal lokal öffnen und testen.
- Zusätzlich sinnvoll: Installer/ISOs, Treiber, Firmware, Karten, lokale Suchsoftware.
- Das Skript kann mehrfach ausgeführt werden. Bereits vorhandene Dateien werden übersprungen.

EOF

  cat > "$TARGET_DIR/00_reader/LISE-MICH.txt" <<'EOF'
Empfohlen:
1. Kiwix Reader auf dem Zielsystem installieren, bevor der PC komplett offline geht.
2. ZIM-Dateien aus 01_zim/ damit öffnen.
3. PDFs lokal mit einem einfachen Reader testen.
4. Von diesem gesamten Verzeichnis mindestens ein Backup auf externer SSD machen.

EOF
}

write_manifest() {
  local manifest="$TARGET_DIR/99_meta/download_manifest.tsv"
  : > "$manifest"

  while IFS=$'\t' read -r kind url path; do
    printf '%s\t%s\t%s\n' "$kind" "$url" "$path" >> "$manifest"
  done < <(build_manifest)
}

build_manifest() {
  if (( ONLY_PDFS == 0 )); then
    printf 'zim\t%s\t%s\n' \
      'https://download.kiwix.org/zim/wikipedia_en_all_nopic.zim' \
      "$TARGET_DIR/01_zim/wikipedia/wikipedia_en_all_nopic.zim"

    printf 'zim\t%s\t%s\n' \
      'https://download.kiwix.org/zim/wikibooks_en_all_maxi.zim' \
      "$TARGET_DIR/01_zim/wikibooks/wikibooks_en_all_maxi.zim"

    printf 'zim\t%s\t%s\n' \
      'https://download.kiwix.org/zim/mdwiki_en_all_maxi.zim' \
      "$TARGET_DIR/01_zim/medizin/mdwiki_en_all_maxi.zim"

    if (( INCLUDE_DE_WIKI )); then
      printf 'zim\t%s\t%s\n' \
        'https://download.kiwix.org/zim/wikipedia_de_all_nopic.zim' \
        "$TARGET_DIR/01_zim/wikipedia/wikipedia_de_all_nopic.zim"
    fi

    if (( INCLUDE_WIKIHOW )); then
      printf 'zim\t%s\t%s\n' \
        'https://download.kiwix.org/zim/wikihow_en_all_maxi.zim' \
        "$TARGET_DIR/01_zim/wikihow/wikihow_en_all_maxi.zim"
    fi
  fi

  if (( ONLY_ZIMS == 0 )); then
    printf 'pdf\t%s\t%s\n' \
      'https://hesperian.org/wp-content/uploads/pdf/en_wtnd_2025/en_wtnd_2025_fm.pdf' \
      "$TARGET_DIR/02_medizin/hesperian/where_there_is_no_doctor_2025_part1.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://hesperian.org/wp-content/uploads/pdf/en_wtnd_2025/en_wtnd_2025_bm.pdf' \
      "$TARGET_DIR/02_medizin/hesperian/where_there_is_no_doctor_2025_part2.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://hesperian.org/wp-content/uploads/pdf/en_dent_2020/en_dent_2020_fm.pdf' \
      "$TARGET_DIR/02_medizin/hesperian/where_there_is_no_dentist_2020.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://hesperian.org/wp-content/uploads/pdf/en_wwhnd_2023/en_wwhnd_2023_fm.pdf' \
      "$TARGET_DIR/02_medizin/hesperian/where_women_have_no_doctor_2023.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://iris.who.int/bitstream/handle/10665/44185/9789241598552_eng.pdf' \
      "$TARGET_DIR/02_medizin/who/who_safe_surgery_2009.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://global-help.org/publications/books/_Primary_Surgery_Volume_One_Non_Trauma_2nd_Edition_Full_Book.pdf' \
      "$TARGET_DIR/02_medizin/surgery/primary_surgery_vol1_non_trauma.pdf"

    printf 'pdf-fallback\t%s\t%s\n' \
      'FALLBACK_LIST:primary_surgery_vol2_trauma' \
      "$TARGET_DIR/02_medizin/surgery/primary_surgery_vol2_trauma.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://www.fao.org/4/ai596e/ai596e.pdf' \
      "$TARGET_DIR/03_landwirtschaft/fao/irrigation_manual.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://www.fao.org/4/f2430e/f2430e.pdf' \
      "$TARGET_DIR/03_landwirtschaft/fao/crop_water_requirements.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://www.fao.org/4/i0959e/i0959e00.pdf' \
      "$TARGET_DIR/03_landwirtschaft/fao/on_farm_post_harvest_management_of_food_grains.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://openknowledge.fao.org/bitstreams/c17aab3c-5210-41b1-a2a9-4e4913e3b28d/download' \
      "$TARGET_DIR/03_landwirtschaft/fao/small_scale_processing_fruits_vegetables.pdf"

    printf 'pdf\t%s\t%s\n' \
      'https://openknowledge.fao.org/bitstreams/47d09334-aaa2-4563-b2a1-648b41169c55/download' \
      "$TARGET_DIR/03_landwirtschaft/fao/field_guide_crop_water_productivity_small_scale_agriculture.pdf"
  fi
}

process_manifest_item() {
  local kind="$1"
  local url="$2"
  local path="$3"

  if [[ "$kind" == "pdf-fallback" && "$url" == "FALLBACK_LIST:primary_surgery_vol2_trauma" ]]; then
    try_download_any "$path" "pdf" \
      'https://global-help.org/publications/books/_Primary_Surgery_Volume_Two_Trauma_2nd_Edition.pdf' \
      'https://global-help.org/publications/books/Primary_Surgery_Volume_Two_Trauma_2nd_Edition.pdf' \
      'https://global-help.org/publications/books/_Primary_Surgery_Volume_Two_Trauma_2nd_Edition_Full_Book.pdf' \
      'https://global-help.org/publications/books/Primary_Surgery_Volume_Two_Trauma_2nd_Edition%20D-Appendices.pdf' || true
    return 0
  fi

  download "$url" "$path" "$kind" || true
}

main() {
  need_cmd df awk sed wc grep
  if ! have aria2c && ! have wget && ! have curl; then
    err "Installiere aria2c oder wget oder curl."
    exit 1
  fi

  mkdir -p \
    "$TARGET_DIR/00_reader" \
    "$TARGET_DIR/01_zim/wikipedia" \
    "$TARGET_DIR/01_zim/wikibooks" \
    "$TARGET_DIR/01_zim/medizin" \
    "$TARGET_DIR/01_zim/wikihow" \
    "$TARGET_DIR/02_medizin/hesperian" \
    "$TARGET_DIR/02_medizin/who" \
    "$TARGET_DIR/02_medizin/surgery" \
    "$TARGET_DIR/03_landwirtschaft/fao" \
    "$TARGET_DIR/04_technik" \
    "$TARGET_DIR/05_repos" \
    "$TARGET_DIR/99_meta"

  init_logs
  write_readmes
  write_manifest

  log "Zielverzeichnis: $TARGET_DIR"
  log "Freier Speicher am Ziel:"
  df -h "$TARGET_DIR" | sed '1d'

  while IFS=$'\t' read -r kind url path; do
    log "Verarbeite ($kind): $(basename "$path")"
    process_manifest_item "$kind" "$url" "$path"
  done < <(build_manifest)

  if have git && (( ONLY_ZIMS == 0 )); then
    clone_or_pull 'https://github.com/OpenSourceEcology/Civilization-Starter-Kit.git' \
      "$TARGET_DIR/05_repos/open_source_ecology_civilization_starter_kit" || true

    clone_or_pull 'https://github.com/OpenSourceEcology/LifeTrac.git' \
      "$TARGET_DIR/05_repos/open_source_ecology_lifetrac" || true

    clone_or_pull 'https://github.com/FreeCAD/FreeCAD-documentation.git' \
      "$TARGET_DIR/05_repos/freecad_documentation" || true

    clone_or_pull 'https://github.com/KiCad/kicad-doc.git' \
      "$TARGET_DIR/05_repos/kicad_docs" || true
  else
    warn "git fehlt oder ONLY_ZIMS=1 gesetzt. Repos werden übersprungen."
  fi

  cat > "$TARGET_DIR/99_meta/NEXT_STEPS.txt" <<'EOF'
Nächste sinnvolle Schritte:
- Kiwix Reader installieren und ZIM-Dateien testweise öffnen
- Zusätzlich lokal sichern:
  - Linux-ISO + Bootstick-Tool
  - Offline-Installer wichtiger Programme
  - Treiber/Firmware für deine echte Hardware
  - Kartenmaterial (z. B. OSM/Topo)
  - Persönliche Dokumente, Kontakte, medizinische Daten, Inventarlisten
- Mindestens 1 Backup auf externer SSD

EOF

  log "Fertig."
  log "Erfolgreich:   $DONE_ITEMS"
  log "Übersprungen:  $SKIPPED_ITEMS"
  log "Fehlgeschlagen:$FAILED_ITEMS"
  log "Run-Log:       $RUN_LOG"
  log "Fehler-Log:    $FAILED_LOG"

  exit 0
}

main "$@"
