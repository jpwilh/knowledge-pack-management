#!/usr/bin/env bash
set -uo pipefail

# Offline Knowledge Pack v3 (1 TB Edition)
# Comprehensive collection: DE/EN, Science, Tech, Agri, Education

EXTERNAL_DRIVE="/media/jpw/Elements"
TARGET_DIR="$EXTERNAL_DRIVE/notfall-pc"
mkdir -p "$TARGET_DIR/99_meta"
RUN_LOG="$TARGET_DIR/99_meta/run_v3_1tb.log"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$RUN_LOG"; }

download() {
    local url="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -s "$dest" && $(stat -c%s "$dest") -gt 10000000 ]]; then
        log "Bereits vorhanden: $(basename "$dest")"
        return 0
    fi
    log "Lade: $url"
    aria2c --dir="$(dirname "$dest")" --out="$(basename "$dest")" \
           --continue=true --max-connection-per-server=8 --split=8 \
           --min-split-size=5M --summary-interval=60 "$url"
}

# --- LISTE DER ARCHIVE (Ziel ca. 1 TB) ---
ZIM="https://download.kiwix.org/zim"

# 1. ENZYKLOPÄDIEN (ca. 250 GB)
download "$ZIM/wikipedia/wikipedia_de_all_maxi_2025-09.zim" "$TARGET_DIR/01_zim/wikipedia/wikipedia_de_all_maxi_2025-09.zim"
download "$ZIM/wikipedia/wikipedia_en_all_maxi_2025-11.zim" "$TARGET_DIR/01_zim/wikipedia/wikipedia_en_all_maxi_2025-11.zim"

# 2. BILDUNG & SCHULE (ca. 100 GB)
# Khan Academy (Videos/Lehrbücher)
download "$ZIM/other/khanacademy_en_all_2025-01.zim" "$TARGET_DIR/01_zim/bildung/khanacademy_en_all.zim"
# TED Talks (Inspiration)
download "$ZIM/ted/ted_en_all_maxi_2024-12.zim" "$TARGET_DIR/01_zim/bildung/ted_en_all.zim"

# 3. WISSENSCHAFT & CHEMIE (ca. 50 GB)
download "$ZIM/libretexts/libretexts.org_en_chem_2025-01.zim" "$TARGET_DIR/01_zim/science/libretexts_chem.zim"
download "$ZIM/libretexts/libretexts.org_en_phys_2025-01.zim" "$TARGET_DIR/01_zim/science/libretexts_phys.zim"
download "$ZIM/wikipedia/wikipedia_de_chemistry_maxi_2026-01.zim" "$TARGET_DIR/01_zim/science/wikipedia_de_chemistry.zim"

# 4. TECHNIK & ELEKTRO (ca. 150 GB)
download "$ZIM/stack_exchange/stackoverflow.com_en_all_2023-11.zim" "$TARGET_DIR/01_zim/tech/stackoverflow.zim"
download "$ZIM/stack_exchange/electronics.stackexchange.com_en_all_2026-02.zim" "$TARGET_DIR/01_zim/tech/electronics_se.zim"
download "$ZIM/ifixit/ifixit_de_all_2025-06.zim" "$TARGET_DIR/01_zim/reparatur/ifixit_de.zim"
download "$ZIM/ifixit/ifixit_en_all_maxi_2025-06.zim" "$TARGET_DIR/01_zim/reparatur/ifixit_en.zim"

# 5. LANDWIRTSCHAFT & ERNÄHRUNG (ca. 20 GB)
download "$ZIM/other/fao_en_all_maxi_2024-05.zim" "$TARGET_DIR/01_zim/agrar/fao_world_agri.zim"
# WikiHow (Praktisches Wissen) - Wir laden die Vollversion falls findbar, sonst nopic
download "$ZIM/other/wikihow_en_all_maxi_2025-11.zim" "$TARGET_DIR/01_zim/agrar/wikihow_en_all.zim"

# 6. KULTUR & BÜCHER
download "$ZIM/gutenberg/gutenberg_de_all_2026-01.zim" "$TARGET_DIR/01_zim/buecher/gutenberg_de.zim"
download "$ZIM/gutenberg/gutenberg_en_all_maxi_2025-12.zim" "$TARGET_DIR/01_zim/buecher/gutenberg_en.zim"

log "Download-Liste für die Nacht ist durch. Gute Nacht!"
