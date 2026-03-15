#!/usr/bin/env bash
set -uo pipefail

# Offline Knowledge Pack v3.1 (2026 Maintenance Edition)
# Comprehensive collection: DE/EN, Science, Tech, Agri, Education
# Target: ~1 TB Storage

# PATHS - Adjusted to detected drive location
EXTERNAL_DRIVE="${NOTFALL_PC_MOUNT}"
TARGET_DIR="$EXTERNAL_DRIVE/notfall-pc"
mkdir -p "$TARGET_DIR/99_meta"
RUN_LOG="$TARGET_DIR/99_meta/run_v3_1tb_$(date +%Y%m%d).log"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$RUN_LOG"; }
warn() { echo "[$(date '+%F %T')] [WARN] $*" | tee -a "$RUN_LOG" >&2; }

# ROBUST DOWNLOAD FUNCTION
download() {
    local url="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    
    # Check if already exists and is large enough (>10MB)
    if [[ -s "$dest" && $(stat -c%s "$dest") -gt 10000000 ]]; then
        log "Bereits vorhanden (groß genug): $(basename "$dest")"
        return 0
    fi

    # Cleanup if it exists but is suspected to be a small error page or previous fail
    if [[ -f "$dest" && $(stat -c%s "$dest") -lt 5000000 ]]; then
        local file_type=$(file -b "$dest" 2>/dev/null)
        if [[ "$file_type" == *"HTML"* || "$file_type" == *"XML"* ]]; then
            log "Lösche fehlerhafte Datei (HTML/XML statt Daten): $(basename "$dest")"
            rm -f "$dest"
        fi
    fi
    rm -f "${dest}.error" # Cleanup any old error markers

    log "Lade: $url"
    # Using curl with -L (follow redirect), -C - (continue), -f (fail on 4xx/5xx)
    # Using a modern User-Agent to avoid some mirror filtering
    curl -L -f -C - -o "$dest" \
         -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
         --connect-timeout 30 --retry 5 "$url"

    # Final validation: Is it what we expect?
    if [[ -f "$dest" ]]; then
        local final_type=$(file -b "$dest" 2>/dev/null)
        if [[ "$final_type" == *"HTML"* || "$final_type" == *"XML"* ]]; then
            warn "FEHLER: Download von $(basename "$dest") ist ungültig ($final_type)!"
            mv "$dest" "${dest}.error"
            return 1
        fi
        # If it's too small after download, it's also a fail
        if [[ $(stat -c%s "$dest") -lt 100000 ]]; then
             warn "FEHLER: Datei $(basename "$dest") ist extrem klein ($(stat -c%s "$dest") Bytes)!"
             mv "$dest" "${dest}.error"
             return 1
        fi
    fi
}

# --- LISTE DER ARCHIVE (Ziel ca. 1 TB) ---
ZIM_BASE="https://download.kiwix.org/zim"

# 1. ENZYKLOPÄDIEN
# Wikipedia DE/EN (Stand 2026)
download "$ZIM_BASE/wikipedia/wikipedia_de_all_maxi_2026-01.zim" "$TARGET_DIR/01_zim/wikipedia/wikipedia_de_all_maxi_2026-01.zim"
download "$ZIM_BASE/wikipedia/wikipedia_en_all_maxi_2026-02.zim" "$TARGET_DIR/01_zim/wikipedia/wikipedia_en_all_maxi_2026-02.zim"

# 2. BILDUNG & SCHULE
# Khan Academy
download "$ZIM_BASE/other/khanacademy_en_all_2023-03.zim" "$TARGET_DIR/01_zim/bildung/khanacademy_en_all.zim"
# TED Talks
download "$ZIM_BASE/ted/ted_en_all_2025-10.zim" "$TARGET_DIR/01_zim/bildung/ted_en_all.zim"

# 3. WISSENSCHAFT & CHEMIE
download "$ZIM_BASE/libretexts/libretexts.org_en_chem_2025-01.zim" "$TARGET_DIR/01_zim/science/libretexts_chem.zim"
download "$ZIM_BASE/libretexts/libretexts.org_en_phys_2026-01.zim" "$TARGET_DIR/01_zim/science/libretexts_phys.zim"
download "$ZIM_BASE/wikipedia/wikipedia_de_chemistry_maxi_2026-01.zim" "$TARGET_DIR/01_zim/science/wikipedia_de_chemistry.zim"

# 4. TECHNIK & ELEKTRO
download "$ZIM_BASE/stack_exchange/stackoverflow.com_en_all_2023-11.zim" "$TARGET_DIR/01_zim/tech/stackoverflow.zim"
download "$ZIM_BASE/stack_exchange/electronics.stackexchange.com_en_all_2026-02.zim" "$TARGET_DIR/01_zim/tech/electronics_se.zim"
download "$ZIM_BASE/ifixit/ifixit_de_all_2025-06.zim" "$TARGET_DIR/01_zim/reparatur/ifixit_de.zim"
download "$ZIM_BASE/ifixit/ifixit_en_all_2025-12.zim" "$TARGET_DIR/01_zim/reparatur/ifixit_en.zim"

# 5. LANDWIRTSCHAFT & ERNÄHRUNG (ZIM + PDFs)
# Zimgit replacements since old ZIMs vanished
download "$ZIM_BASE/other/zimgit-food-preparation_en_2025-04.zim" "$TARGET_DIR/01_zim/agrar/food_prep.zim"
download "$ZIM_BASE/other/zimgit-water_en_2024-08.zim" "$TARGET_DIR/01_zim/agrar/water.zim"

# FAO PDFs (from v2 script)
download "https://www.fao.org/4/ai596e/ai596e.pdf" "$TARGET_DIR/03_landwirtschaft/fao/irrigation_manual.pdf"
download "https://www.fao.org/4/f2430e/f2430e.pdf" "$TARGET_DIR/03_landwirtschaft/fao/crop_water_requirements.pdf"

# 6. MEDIZIN (PDFs)
download "https://global-help.org/publications/books/_Primary_Surgery_Volume_One_Non_Trauma_2nd_Edition_Full_Book.pdf" "$TARGET_DIR/02_medizin/surgery/primary_surgery_vol1_non_trauma.pdf"

# 7. KULTUR & BÜCHER
download "$ZIM_BASE/gutenberg/gutenberg_de_all_2026-01.zim" "$TARGET_DIR/01_zim/buecher/gutenberg_de.zim"
download "$ZIM_BASE/gutenberg/gutenberg_en_all_2025-11.zim" "$TARGET_DIR/01_zim/buecher/gutenberg_en.zim"

# 8. READER TOOLS (FIXED)
KIWIX_ANDROID_LATEST="https://download.kiwix.org/release/kiwix-android/org.kiwix.kiwixmobile.standalone-3.14.0.apk"
SUMATRA_LATEST="https://www.sumatrapdfreader.org/dl/SumatraPDF-3.5.2-64.zip"
# Note: These URLs might need manual update if they change version
download "$KIWIX_ANDROID_LATEST" "$TARGET_DIR/00_reader/kiwix_android.apk"
download "$SUMATRA_LATEST" "$TARGET_DIR/00_reader/SumatraPDF_portable.zip"

log "Download-Liste für die Nacht ist durch. Gute Nacht!"
