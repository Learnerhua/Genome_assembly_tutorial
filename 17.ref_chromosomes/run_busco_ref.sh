#!/usr/bin/env bash
# =============================================================================
# BUSCO re-evaluation script - assess Hi-C scaffolded assembly (gene completeness)
# =============================================================================
# Purpose: re-run BUSCO on the Hi-C scaffolded genome (scaffold_scaffolds_final.fa)
#          and compare with pre-scaffolding NextPolish result (C:99.9%)
# Tool: BUSCO 6.1.0 (busco conda env) + saccharomycetaceae_odb12.2 dataset
# =============================================================================
# Usage: bash run_busco_eval.sh
# Output: 16.hic_scaffolding/busco_result/busco_hic/
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 兼容 bash 调用时 ${BASH_SOURCE[0]} 是相对路径：用绝对路径
if [[ ! "$SCRIPT_DIR" =~ ^/ ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
fi
# 脚本在 16.hic_scaffolding/fixed_chromosomes/，向上 3 级到项目根
PROJECT_ROOT="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
if [[ ! "$PROJECT_ROOT" =~ ^/ ]]; then
    PROJECT_ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
fi

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCAFFOLDED_ASM="$SCRIPT_DIR/ref_scaffold_no_mito.fa"   # Hi-C scaffolded genome
LINEAGE="saccharomycetaceae_odb12.2"                         # yeast lineage dataset
BUSCO_BIN="${BUSCO_BIN}/busco"  # busco env
BUSCO_DOWNLOAD="$PROJECT_ROOT/14.busco_analysis/busco_downloads"  # dataset dir (offline reuse)
BUSCO_OUT="$SCRIPT_DIR/busco_result_ref"                         # output dir (separate)
THREADS="${THREADS:-48}"                                     # number of threads

# =============================================================================
# Pre-checks
# =============================================================================
[[ -f "$SCAFFOLDED_ASM" ]] || { echo "[ERROR] scaffolded genome not found: $SCAFFOLDED_ASM (run run_hic_scaffolding.sh first)"; exit 1; }
[[ -f "$BUSCO_BIN" ]] || { echo "[ERROR] BUSCO not found: $BUSCO_BIN"; exit 1; }
[[ -d "$BUSCO_DOWNLOAD/lineages/$LINEAGE" ]] || { echo "[ERROR] BUSCO dataset missing: $BUSCO_DOWNLOAD/lineages/$LINEAGE"; exit 1; }
mkdir -p "$BUSCO_OUT"

# ensure busco env toolchain in PATH (hmmsearch/blastp/miniprot)
export PATH="${BUSCO_BIN}:$PATH"

# =============================================================================
# Startup info
# =============================================================================
echo "============================================================"
echo "BUSCO re-evaluation (Hi-C scaffolded assembly)"
echo "  started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  assembly: $SCAFFOLDED_ASM"
echo "  lineage: $LINEAGE"
echo "  threads: $THREADS"
echo "  output: $BUSCO_OUT"
echo "============================================================"

# =============================================================================
# Run BUSCO (offline mode)
# =============================================================================
# Key parameters:
#   -i  input assembly FASTA (scaffolded genome)
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
    -i "$SCAFFOLDED_ASM" \
    -l "$LINEAGE" \
    -o busco_ref \
    -m genome \
    -c "$THREADS" \
    --out_path "$BUSCO_OUT" \
    --download_path "$BUSCO_DOWNLOAD" \
    --offline \
    -f 2>&1 | tee "$BUSCO_OUT/busco_hic.log"

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
    echo "Result: $BUSCO_OUT/busco_hic/short_summary.specific.$LINEAGE.busco_hic.txt"
    echo "        (compare with pre-HiC: C:99.9%[S:99.3%,D:0.5%],F:0.0%,M:0.1%)"
    echo "============================================================"
else
    echo "BUSCO re-evaluation failed (exit $CODE)"
    echo "Log: $BUSCO_OUT/busco_hic.log"
    exit $CODE
fi