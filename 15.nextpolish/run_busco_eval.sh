#!/usr/bin/env bash
# =============================================================================
# BUSCO re-evaluation script - assess polished assembly (gene completeness)
# =============================================================================
# Purpose: re-run BUSCO on the NextPolish-polished genome (genome.nextpolish.fasta)
#          and compare with pre-polish nextdenovo result (C:99.5%)
# Tool: BUSCO 6.1.0 (busco conda env) + saccharomycetaceae_odb12.2 dataset
# =============================================================================
# Usage: bash run_busco_eval.sh
# Output: 15.nextpolish/busco_result/busco_nextpolish/
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
POLISHED_ASM="$SCRIPT_DIR/genome.nextpolish.fasta"    # polished genome (NextPolish output)
LINEAGE="saccharomycetaceae_odb12.2"                   # yeast lineage dataset
BUSCO_BIN="${BUSCO_BIN}/busco"          # busco env
BUSCO_DOWNLOAD="$PROJECT_ROOT/14.busco_analysis/busco_downloads"    # dataset dir (offline reuse)
BUSCO_OUT="$SCRIPT_DIR/busco_result"                   # output dir (separate)
THREADS="${THREADS:-48}"                               # number of threads

# =============================================================================
# Pre-checks
# =============================================================================
[[ -f "$POLISHED_ASM" ]] || { echo "[ERROR] polished genome not found: $POLISHED_ASM (run run_nextpolish.sh first)"; exit 1; }
[[ -f "$BUSCO_BIN" ]] || { echo "[ERROR] BUSCO not found: $BUSCO_BIN"; exit 1; }
[[ -d "$BUSCO_DOWNLOAD/lineages/$LINEAGE" ]] || { echo "[ERROR] BUSCO dataset missing: $BUSCO_DOWNLOAD/lineages/$LINEAGE"; exit 1; }
mkdir -p "$BUSCO_OUT"

# ensure busco env toolchain in PATH (hmmsearch/blastp/miniprot)
export PATH="${BUSCO_BIN}:$PATH"

# =============================================================================
# Startup info
# =============================================================================
echo "============================================================"
echo "BUSCO re-evaluation (polished assembly)"
echo "  started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  assembly: $POLISHED_ASM"
echo "  lineage: $LINEAGE"
echo "  threads: $THREADS"
echo "  output: $BUSCO_OUT"
echo "============================================================"

# =============================================================================
# Run BUSCO (offline mode)
# =============================================================================
# Key parameters:
#   -i  input assembly FASTA (polished genome)
#   -l  lineage dataset (saccharomycetaceae_odb12.2, 3105 yeast BUSCOs)
#   -o  output subdir name
#   -m genome  genome assessment mode
#   -c  threads
#   --out_path      output parent dir (busco_result)
#   --download_path dataset dir (contains lineages/ subdir)
#   --offline       offline mode: use local dataset, no network
#   -f  force overwrite existing output dir
# -----------------------------------------------------------------------------
cd "$SCRIPT_DIR"
START=$(date +%s)

"$BUSCO_BIN" \
    -i "$POLISHED_ASM" \
    -l "$LINEAGE" \
    -o busco_nextpolish \
    -m genome \
    -c "$THREADS" \
    --out_path "$BUSCO_OUT" \
    --download_path "$BUSCO_DOWNLOAD" \
    --offline \
    -f 2>&1 | tee "$BUSCO_OUT/busco_nextpolish.log"

CODE=${PIPESTATUS[0]}
END=$(date +%s)
ELAPSED=$((END - START))

echo
echo "============================================================"
if [[ $CODE -eq 0 ]]; then
    echo "BUSCO re-evaluation done"
    echo "  finished: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  elapsed: ${ELAPSED}s"
    echo
    echo "Result: $BUSCO_OUT/busco_nextpolish/short_summary.specific.$LINEAGE.busco_nextpolish.txt"
    echo "        (compare with pre-polish: C:99.5%[S:98.9%,D:0.6%],F:0.0%,M:0.5%)"
    echo "============================================================"
else
    echo "BUSCO re-evaluation failed (exit $CODE)"
    echo "Log: $BUSCO_OUT/busco_nextpolish.log"
    exit $CODE
fi