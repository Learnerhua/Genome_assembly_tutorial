#!/usr/bin/env bash
# =============================================================================
# QUAST re-evaluation - assess Hi-C scaffolding effect (vs reference)
# =============================================================================
# Purpose: compare pre-HiC (NextPolish) vs post-HiC (chromosome-level) assembly
#          using QUAST against yeast reference genome
# Metrics: NA50, NGA50, reference coverage, misassemblies (Hi-C may rearrange)
# Tool: QUAST 5.3.0 (Download/quast, wrapper for Python 3.14 compatibility)
# =============================================================================
# Usage: bash run_quast_eval.sh
# Output: 16.hic_scaffolding/quast_result/quast_compare/
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PRE_HIC_ASM="$PROJECT_ROOT/15.nextpolish/genome.nextpolish.fasta"     # before Hi-C (polished)
POST_HIC_ASM="$SCRIPT_DIR/scaffold_scaffolds_final.fa"                  # after Hi-C (chromosomes)
REF="$PROJECT_ROOT/rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"  # reference
QUAST_WRAPPER="${DATA_ROOT}/Download/quast/quast.sh"           # QUAST wrapper
QUAST_OUT="$SCRIPT_DIR/quast_result"                                    # output dir (separate)

# =============================================================================
# Pre-checks
# =============================================================================
[[ -f "$PRE_HIC_ASM" ]] || { echo "[ERROR] pre-HiC assembly not found: $PRE_HIC_ASM"; exit 1; }
[[ -f "$POST_HIC_ASM" ]] || { echo "[ERROR] Hi-C scaffolded assembly not found: $POST_HIC_ASM (run run_hic_scaffolding.sh first)"; exit 1; }
[[ -f "$REF" ]] || { echo "[ERROR] reference genome not found: $REF"; exit 1; }
[[ -x "$QUAST_WRAPPER" ]] || { echo "[ERROR] QUAST not found: $QUAST_WRAPPER"; exit 1; }
mkdir -p "$QUAST_OUT"

# =============================================================================
# Startup info
# =============================================================================
echo "============================================================"
echo "QUAST re-evaluation (pre-HiC vs post-HiC, vs reference)"
echo "  started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  pre-HiC:  $PRE_HIC_ASM"
echo "  post-HiC: $POST_HIC_ASM"
echo "  ref:      $REF"
echo "  output:   $QUAST_OUT"
echo "============================================================"

# =============================================================================
# Run QUAST (dual-assembly comparison + reference)
# =============================================================================
# Key parameters:
#   two FASTAs    pre-HiC + post-HiC together → comparison table
#   -r reference  (yeast R64-1-1) → computes NA50, ref coverage, misassemblies
#   -t 1 --memory-efficient  avoid joblib multiprocessing (Python 3.14 compat)
#   -o output dir
#   -l "name1,name2"  column labels in comparison table
# -----------------------------------------------------------------------------
cd "$SCRIPT_DIR"
START=$(date +%s)

"$QUAST_WRAPPER" \
    "$PRE_HIC_ASM" "$POST_HIC_ASM" \
    -r "$REF" \
    -t 1 \
    --memory-efficient \
    -o "$QUAST_OUT/quast_compare" \
    -l "nextpolish_prehic,hic_scaffolded" 2>&1 | tee "$QUAST_OUT/quast_compare.log"

CODE=${PIPESTATUS[0]}
END=$(date +%s)
ELAPSED=$((END - START))

echo
echo "============================================================"
if [[ $CODE -eq 0 ]]; then
    echo "QUAST re-evaluation done"
    echo "  finished: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  elapsed: ${ELAPSED}s"
    echo
    echo "Result: $QUAST_OUT/quast_compare/report.html  (browser opens comparison)"
    echo "        $QUAST_OUT/quast_compare/report.tsv   (machine readable)"
    echo "        (metrics: NA50/NGA50/reference coverage/misassemblies)"
    echo "============================================================"
else
    echo "QUAST re-evaluation failed (exit $CODE)"
    echo "Log: $QUAST_OUT/quast_compare.log"
    exit $CODE
fi